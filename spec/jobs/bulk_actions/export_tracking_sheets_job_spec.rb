# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ExportTrackingSheetsJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action, action_type: 'export_tracking_sheets') }
  let(:log) { StringIO.new }

  let(:solr_doc) do
    { Search::Fields::ID => druid, Search::Fields::TITLE => 'Some label' }
  end

  let(:pdf) { instance_double(Prawn::Document) }

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return(solr_doc)
    allow(TracksheetService).to receive(:call).and_return(pdf)
    allow(pdf).to receive(:render_file)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'fetches each solr document and passes presenters to TracksheetService' do
    job.perform_now

    expect(Sdr::Repository).to have_received(:find_solr).with(druid:)
    expect(TracksheetService).to have_received(:call) do |solr_doc_presenters:|
      expect(solr_doc_presenters.length).to eq(1)
      expect(solr_doc_presenters.first).to be_a(SolrDocPresenter)
      expect(solr_doc_presenters.first.druid).to eq(druid)
    end
  end

  it 'renders the PDF to the export filepath' do
    job.perform_now

    expect(pdf).to have_received(:render_file).with(bulk_action.export_filepath)
  end

  it 'records the correct counts' do
    job.perform_now

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when a druid is not found in Solr' do
    before do
      allow(Sdr::Repository)
        .to receive(:find_solr).with(druid:)
                               .and_raise(Sdr::Repository::NotFoundResponse, "Object not found: #{druid}")
    end

    it 'records the druid as failed and still generates a PDF for the remaining druids' do
      job.perform_now

      expect(TracksheetService).to have_received(:call) do |solr_doc_presenters:|
        expect(solr_doc_presenters).to be_empty
      end

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when rendering the PDF fails' do
    before do
      allow(pdf).to receive(:render_file).and_raise(StandardError, 'disk full')
      allow(Honeybadger).to receive(:notify)
    end

    it 'logs the error and notifies Honeybadger' do
      job.perform_now

      expect(Honeybadger).to have_received(:notify)
      expect(log.string).to include('ExportTrackingSheetsJob failed StandardError disk full')
    end
  end

  context 'when processing multiple druids' do
    subject(:job) { described_class.new(bulk_action:, druids: [druid, second_druid]) }

    let(:second_druid) { 'druid:hj185xx2222' }
    let(:second_solr_doc) { { Search::Fields::ID => second_druid, Search::Fields::TITLE => 'Another label' } }

    before do
      allow(Sdr::Repository).to receive(:find_solr).with(druid: second_druid).and_return(second_solr_doc)
    end

    it 'passes all presenters to TracksheetService' do
      job.perform_now

      expect(TracksheetService).to have_received(:call) do |solr_doc_presenters:|
        expect(solr_doc_presenters.length).to eq(2)
        expect(solr_doc_presenters.map(&:druid)).to contain_exactly(druid, second_druid)
      end

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end
end
