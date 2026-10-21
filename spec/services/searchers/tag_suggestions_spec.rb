# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::TagSuggestions do
  let(:user) { create(:user, :admin) }
  let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }

  context 'with a stubbed Solr' do
    let(:solr_response) do
      {
        'facet_counts' => {
          'facet_fields' => {
            Search::Fields::PROJECTS => ['Project 1', 2]
          }
        }
      }
    end

    before do
      allow(Search::SolrService).to receive(:post).and_return(solr_response)
    end

    it 'returns matching tags from Solr' do
      results = described_class.call(query: ' proj 1. ', tag_type: 'project', user_scope:)

      expect(results.to_a).to eq(['Project 1'])
      expect(Search::SolrService).to have_received(:post)
        .with(request: { q: '*:*',
                         fq: [],
                         rows: 0,
                         facet: true,
                         'facet.field': 'project_tag_ssim',
                         'facet.matches': '(?i).*proj\\ 1\\..*',
                         'facet.mincount': 1,
                         'facet.limit': 25,
                         'facet.sort': 'index' })
    end

    it 'restricts other tags to valid tags that are not Registered By tags' do
      described_class.call(query: 'tag', tag_type: 'other', user_scope:)

      expect(Search::SolrService).to have_received(:post)
        .with(request: hash_including('facet.field': 'exploded_nonproject_tag_ssimdv',
                                      'facet.matches': '(?i)(?!registered by : )(?=.* : ).*tag.*'))
    end
  end

  context 'with an unknown tag type' do
    it 'raises an error' do
      expect { described_class.call(query: 'tag', tag_type: 'registered_by', user_scope:) }
        .to raise_error(ArgumentError, 'Unknown tag type: registered_by')
    end
  end

  context 'with Solr', :solr do
    before do
      create(:solr_item,
             projects: ['Argo Project : Phase 1', 'Other project'],
             tags: ['Argo Tag : Child : Grandchild', 'Registered By : argo_user', 'Unrelated : Tag'],
             tickets: %w[ARGO-123 OTHER-456])
    end

    it 'returns project tags matching the query case-insensitively' do
      results = described_class.call(query: 'argo', tag_type: 'project', user_scope:)

      expect(results.to_a).to eq(['Argo Project : Phase 1'])
    end

    it 'returns ticket tags matching the query' do
      results = described_class.call(query: 'argo', tag_type: 'ticket', user_scope:)

      expect(results.to_a).to eq(['ARGO-123'])
    end

    it 'returns other tags with at least two parts, excluding Registered By tags' do
      results = described_class.call(query: 'argo', tag_type: 'other', user_scope:)

      expect(results.to_a).to eq(['Argo Tag : Child', 'Argo Tag : Child : Grandchild'])
    end

    context 'with specific permission targets' do
      let(:user) { create(:user, :reader) }
      let(:restricted_apo_druid) { 'druid:bc123df4567' }

      before do
        create(:solr_item, apo_druid: restricted_apo_druid, projects: ['Argo hidden project'])
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
      end

      it 'only returns tags for readable items' do
        results = described_class.call(query: 'argo', tag_type: 'project', user_scope:)

        expect(results.to_a).to eq(['Argo Project : Phase 1'])
      end
    end
  end
end
