# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ExportModsJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action, action_type: 'export_mods') }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:log) { StringIO.new }

  let(:mods_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <mods xmlns="http://www.loc.gov/mods/v3">
        <titleInfo>
          <title>Test Object Title</title>
        </titleInfo>
      </mods>
    XML
  end

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 0, job:).tap do |item|
      allow(item).to receive(:cocina_object).and_return(cocina_object)
    end
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(PurlFetcher::Client::Mods).to receive(:create).and_return(mods_xml)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'performs the job and creates a zip file containing the MODS XML' do
    job.perform_now

    expect(PurlFetcher::Client::Mods).to have_received(:create).with(cocina: cocina_object)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)

    expect(File).to exist(bulk_action.export_filepath)
    Zip::File.open(bulk_action.export_filepath) do |zip_file|
      expect(zip_file.glob('*').map(&:name)).to eq ['bc123df4567.xml']
      content = zip_file.read('bc123df4567.xml')
      expect(content).to include('<title>Test Object Title</title>')
    end
  end

  context 'when the user lacks read permission' do
    before do
      allow(job_item).to receive(:check_read_ability?).and_return(false)
    end

    it 'does not add the object to the zip file' do
      job.perform_now

      expect(PurlFetcher::Client::Mods).not_to have_received(:create)

      expect(File).to exist(bulk_action.export_filepath)
      Zip::File.open(bulk_action.export_filepath) do |zip_file|
        expect(zip_file.glob('*').map(&:name)).to be_empty
      end
    end
  end

  context 'when processing multiple druids' do
    subject(:job) { described_class.new(bulk_action:, druids: [druid, second_druid]) }

    let(:second_druid) { 'druid:hj185xx2222' }
    let(:second_cocina_object) { build(:dro_with_metadata, id: second_druid) }

    let(:second_job_item) do
      described_class::JobItem.new(druid: second_druid, index: 1, job:).tap do |item|
        allow(item).to receive(:cocina_object).and_return(second_cocina_object)
      end
    end

    before do
      allow(described_class::JobItem).to receive(:new).and_call_original
      allow(described_class::JobItem).to receive(:new).with(druid:, index: 0, job:).and_return(job_item)
      allow(described_class::JobItem).to receive(:new).with(druid: second_druid, index: 1,
                                                            job:).and_return(second_job_item)
    end

    it 'exports MODS XML for each druid in the zip file' do
      job.perform_now

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(0)

      Zip::File.open(bulk_action.export_filepath) do |zip_file|
        expect(zip_file.glob('*').map(&:name).sort).to eq ['bc123df4567.xml', 'hj185xx2222.xml']
      end
    end
  end
end
