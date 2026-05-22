# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TracksheetService do
  let(:druid) { 'druid:bc123df4567' }
  let(:solr_doc) { { Search::Fields::ID => druid, Search::Fields::TITLE => title } }
  let(:presenter) { SolrDocPresenter.new(solr_doc:) }
  let(:instance) { described_class.new(solr_doc_presenter: presenter) }
  let(:title) { 'Test title' }

  # NOTE: expectations use "include" rather than "eq" because doc_to_table appends a timestamp row
  describe '#doc_to_table' do
    subject(:call) { instance.send(:doc_to_table) }

    context 'when normal length title' do
      it 'includes the title as the object label' do
        expect(call).to include(['Object Label:', 'Test title'])
      end
    end

    context 'when really long title' do
      let(:title) { 'Stanford University. School of Engineeering Roger Howe Professorship: Stanford (Calif.), 2010-01-21.  And more stuff goes here' } # rubocop:disable Layout/LineLength

      it 'truncates the title to 110 characters' do
        expect(call).to include(
          ['Object Label:', 'Stanford University. School of Engineeering Roger Howe Professorship: Stanford (Calif.), 2010-01-21.  And m...'] # rubocop:disable Layout/LineLength
        )
      end
    end

    context 'when no title' do
      let(:title) { nil }

      it 'includes a blank object label' do
        expect(call).to include(['Object Label:', ''])
      end
    end

    context 'with a project name' do
      let(:solr_doc) do
        { Search::Fields::ID => druid,
          Search::Fields::TITLE => title,
          Search::Fields::PROJECTS => ['School of Engineering photograph collection'] }
      end

      it 'adds the project name' do
        expect(call).to include(['Project Name:', 'School of Engineering photograph collection'])
      end
    end

    context 'with tags' do
      let(:nbsp) { Prawn::Text::NBSP }
      let(:solr_doc) do
        { Search::Fields::ID => druid,
          Search::Fields::TITLE => title,
          Search::Fields::OTHER_TAGS => ['Some : First : Tag', 'Some : Second : Tag', 'Project : Ignored'] }
      end

      it 'adds the tags, ignoring project tags' do
        expect(call).to include(['Tags:', "Some#{nbsp}:#{nbsp}First#{nbsp}:#{nbsp}Tag\nSome#{nbsp}:#{nbsp}Second#{nbsp}:#{nbsp}Tag"]) # rubocop:disable Layout/LineLength
      end
    end

    context 'with a catalog_record_id' do
      let(:solr_doc) do
        { Search::Fields::ID => druid,
          Search::Fields::TITLE => title,
          Search::Fields::CATALOG_RECORD_ID => ['in12345'] }
      end

      it 'adds the catalog record id' do
        expect(call).to include(['Folio Instance HRID:', 'in12345'])
      end
    end

    context 'with a source_id' do
      let(:solr_doc) do
        { Search::Fields::ID => druid,
          Search::Fields::TITLE => title,
          Search::Fields::SOURCE_ID => 'source:123' }
      end

      it 'adds the source id' do
        expect(call).to include(['Source ID:', 'source:123'])
      end
    end

    context 'with a barcode' do
      let(:solr_doc) do
        { Search::Fields::ID => druid,
          Search::Fields::TITLE => title,
          Search::Fields::BARCODES => ['barcode123'] }
      end

      it 'adds the barcode' do
        expect(call).to include(['Barcode:', 'barcode123'])
      end
    end

    it 'always includes a date printed row' do
      expect(call.map(&:first)).to include('Date Printed:')
    end
  end
end
