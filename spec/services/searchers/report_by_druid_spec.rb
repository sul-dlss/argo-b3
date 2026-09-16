# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::ReportByDruid do
  let(:user) { create(:user, :admin) }
  let(:druids) { ['druid:rt276nw8963', 'druid:kk754nn3333'] }
  let(:fields) { [Reports::Fields::DRUID.field, Reports::Fields::PURL.field] }

  before { Current.effective_groups = user.groups }

  context 'when streaming results' do
    subject(:results) { described_class.call(druids:, fields:, stream:, rows: 10) }

    let(:stream) { StringIO.new }

    before do
      allow(Search::SolrService).to receive(:stream)
    end

    it 'returns CSV results from Solr' do
      results
      expect(Search::SolrService).to have_received(:stream) do |args|
        solr_query = args[:request].with_indifferent_access
        expect(solr_query['fq']).to eq(['id:("druid:rt276nw8963" OR "druid:kk754nn3333")'])
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
    subject(:results) { described_class.call(druids:, fields:, rows: 10) }

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
        expect(solr_query['fq']).to eq(['id:("druid:rt276nw8963" OR "druid:kk754nn3333")'])
        expect(solr_query['fl']).to eq(fields)
        expect(solr_query['rows']).to eq(10)
        expect(solr_query['wt']).to eq(:csv)
        expect(solr_query['csv.mv.separator']).to eq(';')
      end
    end
  end

  context 'with specific permission targets', :solr do
    let(:user) { create(:user, :reader) }
    let(:restricted_apo_druid) { 'druid:bc123df4567' }
    let!(:visible_document) { create(:solr_item) }
    let!(:hidden_document) { create(:solr_item, apo_druid: restricted_apo_druid) }

    before do
      Current.effective_groups = user.groups
      create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    end

    it 'filters previews and streamed downloads to only readable items' do
      druids = [visible_document, hidden_document].pluck(Search::Fields::ID)
      fields = [Search::Fields::ID]
      preview = described_class.call(druids:, fields:, rows: 10)
      stream = StringIO.new
      described_class.call(druids:, fields:, rows: 10, stream:)

      expect(preview.map(&:fields).flatten).to eq([visible_document.fetch(Search::Fields::ID)])
      expect(stream.string).to include(visible_document.fetch(Search::Fields::ID))
      expect(stream.string).not_to include(hidden_document.fetch(Search::Fields::ID))
    end
  end
end
