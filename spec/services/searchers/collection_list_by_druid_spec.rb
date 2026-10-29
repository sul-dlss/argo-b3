# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::CollectionListByDruid do
  context 'with stubbed Solr' do
    let(:solr_response) do
      {
        'response' => {
          'numFound' => 2,
          'docs' => [
            { 'id' => 'druid:bc123df4567', 'display_title_ss' => 'Art History Slides' },
            { 'id' => 'druid:xz987wv6543', 'display_title_ss' => 'Maps of Palo Alto' }
          ]
        }
      }
    end
    let(:druids) { %w[druid:xz987wv6543 druid:gh456jk7890 druid:bc123df4567] }

    before do
      allow(Search::SolrService).to receive(:post).and_return(solr_response)
    end

    it 'returns [title, druid] pairs in druid order, omitting collections that are not found' do
      expect(described_class.call(druids:))
        .to eq([['Maps of Palo Alto', 'druid:xz987wv6543'], ['Art History Slides', 'druid:bc123df4567']])

      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['fq'])
          .to eq(["#{Search::Fields::OBJECT_TYPES}:collection",
                  'id:("druid\\:xz987wv6543" OR "druid\\:gh456jk7890" OR "druid\\:bc123df4567")'])
        expect(solr_query['fl']).to eq([Search::Fields::ID, Search::Fields::TITLE])
        expect(solr_query['rows']).to eq(3)
      end
    end

    context 'with a user scope' do
      let(:user) { create(:user, :reader) }
      let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: 'druid:gh456jk7890')
      end

      it 'restricts to the collections the user can edit' do
        described_class.call(druids:, user_scope:)

        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request][:fq]).to include(Search::PermissionFilter.call(user_scope:, editable: true))
        end
      end
    end

    context 'with an APO' do
      it 'limits to the collections governed by the APO' do
        described_class.call(druids:, apo_druid: 'druid:hv992ry2431')

        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request][:fq]).to include("#{Search::Fields::APO_DRUID}:\"druid\\:hv992ry2431\"")
        end
      end
    end

    context 'when there are no druids' do
      it 'returns no collections without querying Solr' do
        expect(described_class.call(druids: [])).to eq([])

        expect(Search::SolrService).not_to have_received(:post)
      end
    end
  end

  context 'with Solr', :solr do
    let(:user) { create(:user, :reader) }
    let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }
    let(:editable_collection_druid) { 'druid:gh456jk7890' }
    let(:druids) { ['druid:bc123df4567', editable_collection_druid] }

    before do
      create(:solr_collection, druid: 'druid:bc123df4567', title: 'Art History Slides')
      create(:solr_collection, druid: editable_collection_druid, title: 'Editable Art Collection')
      create(:permission, :edit, workgroup: user.groups.first, target_druid: editable_collection_druid)
    end

    it 'returns only the collections the user can edit when given a user scope' do
      expect(described_class.call(druids:, user_scope:))
        .to eq([['Editable Art Collection', editable_collection_druid]])
    end

    it 'returns all of the collections when not given a user scope' do
      expect(described_class.call(druids:))
        .to eq([['Art History Slides', 'druid:bc123df4567'],
                ['Editable Art Collection', editable_collection_druid]])
    end
  end
end
