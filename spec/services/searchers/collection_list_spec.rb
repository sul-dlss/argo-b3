# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::CollectionList do
  let(:user) { create(:user, :admin) }
  let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }

  context 'with stubbed Solr' do
    let(:solr_response) do
      {
        'response' => {
          'numFound' => 2,
          'docs' => [
            { 'id' => 'druid:bc123df4567', 'display_title_ss' => 'Art History Slides' },
            { 'id' => 'druid:xz987wv6543', 'display_title_ss' => 'Art History Slides' }
          ]
        }
      }
    end

    before do
      allow(Search::SolrService).to receive(:post).and_return(solr_response)
    end

    it 'returns [title, druid] pairs for collections matching the title' do
      expect(described_class.call(query: 'art hist', user_scope:))
        .to eq([['Art History Slides', 'druid:bc123df4567'], ['Art History Slides', 'druid:xz987wv6543']])

      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['q']).to eq('art hist*')
        expect(solr_query['defType']).to eq('edismax')
        expect(solr_query['mm']).to eq('100%')
        expect(solr_query['fq']).to eq(["#{Search::Fields::OBJECT_TYPES}:collection"])
        expect(solr_query['fl']).to eq([Search::Fields::ID, Search::Fields::TITLE])
        expect(solr_query['rows']).to eq(25)
      end
    end

    context 'with a query containing Solr special characters' do
      it 'escapes the query' do
        described_class.call(query: 'maps: (1900)', user_scope:)

        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request][:q]).to eq('maps\\: \\(1900\\)*')
        end
      end
    end

    context 'with an APO' do
      it 'limits to the collections governed by the APO' do
        described_class.call(query: 'art', user_scope:, apo_druid: 'druid:hv992ry2431')

        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request][:fq]).to include("#{Search::Fields::APO_DRUID}:\"druid\\:hv992ry2431\"")
        end
      end
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user, :reader) }

      before do
        create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: 'druid:gh456jk7890')
      end

      it 'restricts to the collections the user can see' do
        described_class.call(query: 'art', user_scope:)

        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request][:fq]).to include(Search::PermissionFilter.call(user_scope:))
        end
      end
    end
  end

  context 'with Solr', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_collection_druid) { 'druid:gh456jk7890' }

    before do
      create(:solr_collection, druid: 'druid:bc123df4567', title: 'Art History Slides')
      create(:solr_collection, druid: 'druid:dm456jk7812', title: 'Maps of Palo Alto')
      create(:solr_collection, druid: restricted_collection_druid, title: 'Restricted Art Collection')
      create(:solr_item, druid: 'druid:kp789pq0123', title: 'Art History Lecture')
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_collection_druid)
    end

    it 'returns the visible collections with titles matching the words, treating the last as a prefix' do
      expect(described_class.call(query: 'art hist', user_scope:))
        .to eq([['Art History Slides', 'druid:bc123df4567']])
      expect(described_class.call(query: 'art', user_scope:).map(&:last)).to eq(['druid:bc123df4567'])
    end

    context 'with an APO' do
      let(:apo_druid) { 'druid:hv992ry2431' }

      before do
        create(:solr_collection, druid: 'druid:fr234ty5678', title: 'Art Prints', apo_druid:)
      end

      it 'returns only the collections governed by the APO' do
        expect(described_class.call(query: 'art', user_scope:, apo_druid:))
          .to eq([['Art Prints', 'druid:fr234ty5678']])
      end
    end
  end
end
