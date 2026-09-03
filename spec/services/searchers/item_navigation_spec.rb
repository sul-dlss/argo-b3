# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::ItemNavigation do
  let(:navigation) { described_class.call(search_form:, position:) }
  let(:search_form) { SearchForm.new(query:) }
  let(:query) { 'test' }
  let(:position) { 3 }
  let(:previous_druid) { 'druid:bc123df4567' }
  let(:current_druid) { 'druid:cd234eg5678' }
  let(:next_druid) { 'druid:df345fh6789' }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 10,
        'docs' => [
          { 'id' => previous_druid },
          { 'id' => current_druid },
          { 'id' => next_druid }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns both neighboring druids and the current total from one Solr request' do
    expect(navigation.previous_druid).to eq(previous_druid)
    expect(navigation.next_druid).to eq(next_druid)
    expect(navigation.total_results).to eq(10)

    expect(Search::SolrService).to have_received(:post).once do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['q']).to eq(query)
      expect(solr_query['fl']).to eq([Search::Fields::ID])
      expect(solr_query['rows']).to eq(3)
      expect(solr_query['start']).to eq(1)
    end
  end

  context 'when the item is first in the results' do
    let(:position) { 1 }
    let(:solr_response) do
      {
        'response' => {
          'numFound' => 10,
          'docs' => [{ 'id' => current_druid }, { 'id' => next_druid }]
        }
      }
    end

    it 'returns only the next druid' do
      expect(navigation.previous_druid).to be_nil
      expect(navigation.next_druid).to eq(next_druid)
    end
  end

  context 'when the item is last in the results' do
    let(:position) { 10 }
    let(:solr_response) do
      {
        'response' => {
          'numFound' => 10,
          'docs' => [{ 'id' => previous_druid }, { 'id' => current_druid }]
        }
      }
    end

    it 'returns only the previous druid' do
      expect(navigation.previous_druid).to eq(previous_druid)
      expect(navigation.next_druid).to be_nil
    end
  end

  context 'when a sort is specified' do
    let(:search_form) { SearchForm.new(query:, sort: 'druid') }

    it 'includes the sort value in the Solr request' do
      navigation

      expect(Search::SolrService).to have_received(:post) do |args|
        expect(args[:request].with_indifferent_access['sort']).to eq('id asc')
      end
    end
  end
end
