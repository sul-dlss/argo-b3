# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Report do
  let(:search_form) { SearchForm.new(query:) }
  let(:query) { 'test' }
  let(:fields) { [Reports::Fields::DRUID.field, Reports::Fields::PURL.field] }

  context 'when streaming results' do
    subject(:results) { described_class.call(search_form:, fields:, stream:, rows: 10) }

    let(:stream) { StringIO.new }

    before do
      allow(Search::SolrService).to receive(:stream)
    end

    it 'returns CSV results from Solr' do
      results
      expect(Search::SolrService).to have_received(:stream) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['q']).to eq(query)
        expect(solr_query['fl']).to eq(fields)
        expect(solr_query['rows']).to eq(10)
        expect(solr_query['wt']).to eq(:csv)
        expect(solr_query['csv.mv.separator']).to eq(';')
        expect(args[:stream]).to eq(stream)
        expect(args[:replacement_header]).to eq("Druid,PURL\n")
      end
    end
  end

  context 'when not streaming results' do
    subject(:results) { described_class.call(search_form:, fields:, rows: 10) }

    let(:csv_string) do
      <<~CSV
        #{Search::Fields::BARE_DRUID},#{Search::Fields::PURL}
        rt276nw8963,https://purl.stanford.edu/rt276nw8963
        kk754nn3333,https://purl.stanford.edu/kk754nn3333
      CSV
    end

    before do
      allow(Search::SolrService).to receive(:post).and_return(csv_string)
    end

    it 'returns CSV::Table results from Solr' do
      results_table = results
      expect(results_table).to be_a(CSV::Table)
      expect(results_table.length).to eq(2)
      expect(results_table[0]['Druid']).to eq('rt276nw8963')
      expect(results_table[0]['PURL']).to eq('https://purl.stanford.edu/rt276nw8963')

      expect(Search::SolrService).to have_received(:post) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['q']).to eq(query)
        expect(solr_query['fl']).to eq(fields)
        expect(solr_query['rows']).to eq(10)
        expect(solr_query['wt']).to eq(:csv)
        expect(solr_query['csv.mv.separator']).to eq(';')
      end
    end
  end
end
