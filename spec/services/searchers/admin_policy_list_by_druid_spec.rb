# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::AdminPolicyListByDruid do
  context 'with stubbed Solr' do
    let(:solr_response) do
      {
        'response' => {
          'numFound' => 2,
          'docs' => [
            { 'id' => 'druid:hv992ry2431', 'display_title_ss' => 'University Archives APO' },
            { 'id' => 'druid:xz987wv6543', 'display_title_ss' => 'Maps APO' }
          ]
        }
      }
    end
    let(:druids) { %w[druid:xz987wv6543 druid:gh456jk7890 druid:hv992ry2431] }

    before do
      allow(Search::SolrService).to receive(:post).and_return(solr_response)
    end

    it 'returns [title, druid] pairs in druid order, omitting APOs that are not found' do
      expect(described_class.call(druids:))
        .to eq([['Maps APO', 'druid:xz987wv6543'], ['University Archives APO', 'druid:hv992ry2431']])

      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['fq'])
          .to eq(['objectType_ssimdv:APO',
                  'id:("druid\\:xz987wv6543" OR "druid\\:gh456jk7890" OR "druid\\:hv992ry2431")'])
        expect(solr_query['fl']).to eq(%w[id display_title_ss])
        expect(solr_query['rows']).to eq(3)
      end
    end

    context 'with a user scope' do
      let(:user) { create(:user, :reader) }
      let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }

      before do
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: 'druid:gh456jk7890')
      end

      it 'restricts to the APOs the user can see' do
        described_class.call(druids:, user_scope:)

        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request][:fq]).to include(Search::PermissionFilter.call(user_scope:))
        end
      end
    end

    context 'when there are no druids' do
      it 'returns no APOs without querying Solr' do
        expect(described_class.call(druids: [])).to eq([])

        expect(Search::SolrService).not_to have_received(:post)
      end
    end
  end

  context 'with Solr', :solr do
    let(:collection_druid) { 'druid:bc123df4567' }

    before do
      create(:solr_admin_policy, druid: 'druid:hv992ry2431', title: 'University Archives APO')
      create(:solr_collection, druid: collection_druid, title: 'Art History Slides')
    end

    it 'returns only the APOs' do
      expect(described_class.call(druids: ['druid:hv992ry2431', collection_druid]))
        .to eq([['University Archives APO', 'druid:hv992ry2431']])
    end
  end
end
