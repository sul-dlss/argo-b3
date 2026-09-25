# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Item do
  let(:user) { create(:user, :admin) }
  let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }
  let(:results) { described_class.call(search_form:, user_scope:) }
  let(:search_form) { ResultsSearchForm.new(query:) }
  let(:query) { 'test' }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 1,
        'docs' => [
          { 'id' => 'druid:ab123cd4567' }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns search results from Solr' do
    expect(results).to be_a(SearchResults::Items)
    expect(results.solr_response).to eq(solr_response)

    # This tests the parts of the query that aren't tested by ItemQueryBuilder spec.
    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      # Only testing one field here so that the test is not brittle.
      expect(solr_query['fl']).to include(Search::Fields::ID)
      # Only testing one field here so that the test is not brittle.
      facet_json = JSON.parse(solr_query[:'json.facet']).with_indifferent_access
      expect(facet_json).to include(
        Search::Fields::OBJECT_TYPES
      )
      expect(solr_query['rows']).to eq(50)
      expect(solr_query['start']).to eq(0)
    end
  end

  context 'when the search form is blank' do
    let(:search_form) { ResultsSearchForm.new }

    it 'requests a page of results' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['rows']).to eq(50)
      end
    end
  end

  context 'when on page 3' do
    let(:search_form) { ResultsSearchForm.new(query:, page: 3) }

    it 'calculates the correct start value' do
      results
      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['start']).to eq(100)
      end
    end
  end

  context 'when sorting', :solr do
    let(:search_form) { ResultsSearchForm.new(query: 'Test', sort:) }
    let!(:oldest) do
      create(:solr_item, source_id: 'sul:001', earliest_registered_date: 3.years.ago,
                         last_deposited_date: 3.years.ago)
    end
    let!(:middle) do
      create(:solr_item, source_id: 'sul:002', earliest_registered_date: 2.years.ago,
                         last_deposited_date: 2.years.ago)
    end
    let!(:newest) do
      create(:solr_item, source_id: 'sul:003', earliest_registered_date: 1.year.ago,
                         last_deposited_date: 1.year.ago)
    end
    let(:ascending_druids) { [oldest, middle, newest].map { |solr_doc| solr_doc.fetch(Search::Fields::ID) } }

    before do
      allow(Search::SolrService).to receive(:post).and_call_original
    end

    context 'when sorting by last deposited date ascending' do
      let(:sort) { 'last_deposited_date_asc' }

      it 'returns the least recently deposited first' do
        expect(results.map(&:druid)).to eq(ascending_druids)
      end
    end

    context 'when sorting by last deposited date descending' do
      let(:sort) { 'last_deposited_date_desc' }

      it 'returns the most recently deposited first' do
        expect(results.map(&:druid)).to eq(ascending_druids.reverse)
      end
    end

    context 'when sorting by registered date ascending' do
      let(:sort) { 'registered_date_asc' }

      it 'returns the least recently registered first' do
        expect(results.map(&:druid)).to eq(ascending_druids)
      end
    end

    context 'when sorting by registered date descending' do
      let(:sort) { 'registered_date_desc' }

      it 'returns the most recently registered first' do
        expect(results.map(&:druid)).to eq(ascending_druids.reverse)
      end
    end

    context 'when sorting by source id' do
      let(:sort) { 'source_id' }

      it 'returns the results in source id order' do
        expect(results.map(&:druid)).to eq(ascending_druids)
      end
    end
  end

  context 'when sorting by title', :solr do
    let(:search_form) { ResultsSearchForm.new(query: 'atlas', sort: 'title') }
    # Created out of alphabetical order, and mixed case, since the sort key DSA indexes is downcased.
    let!(:zebra) { create(:solr_item, title: 'Zebra atlas') }
    let!(:apple) { create(:solr_item, title: 'apple atlas') }
    let!(:banana) { create(:solr_item, title: 'Banana atlas') }
    let(:alphabetical_druids) do
      [apple, banana, zebra].map { |solr_doc| solr_doc.fetch(Search::Fields::ID) }
    end

    before do
      allow(Search::SolrService).to receive(:post).and_call_original
    end

    it 'returns the results in case-insensitive title order' do
      expect(results.map(&:druid)).to eq(alphabetical_druids)
    end
  end

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }
    let!(:visible_document) { create(:solr_item) }
    let(:search_form) { ResultsSearchForm.new(query: 'Test') }

    before do
      allow(Search::SolrService).to receive(:post).and_call_original
      create(:solr_item, apo_druid: restricted_apo_druid, content_type: 'image')
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'filters results, counts, and facets to only readable items' do
      results = described_class.call(search_form:, user_scope:)

      expect(results.map(&:druid)).to eq([visible_document.fetch(Search::Fields::ID)])
      expect(results.total_results).to eq(1)
      expect(results.solr_response.fetch('facets').fetch(Search::Fields::CONTENT_TYPES).fetch('buckets'))
        .to eq([{ 'val' => 'book', 'count' => 1 }])
    end

    it 'retains authorization when a facet excludes its own selected filter' do
      results = described_class.call(search_form: ResultsSearchForm.new(query: 'Test', content_types: ['image']),
                                     user_scope:)

      expect(results.total_results).to eq(0)
      expect(results.solr_response.fetch('facets').fetch(Search::Fields::CONTENT_TYPES).fetch('buckets'))
        .to eq([{ 'val' => 'book', 'count' => 1 }])
    end
  end
end
