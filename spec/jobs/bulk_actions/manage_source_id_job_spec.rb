# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ManageSourceIdJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:, close_version: false) }

  let(:druid) { 'druid:bc123df4567' }
  let(:source_id) { 'test:123' }
  let(:new_source_id) { 'test:456' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, source_id:) }

  let(:bulk_action) { create(:bulk_action) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 2, job:, row:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
      allow(job_item).to receive(:close_version_if_needed!)
    end
  end

  let(:csv_file) do
    [
      'druid,source_id',
      [druid, new_source_id].join(',')
    ].join("\n")
  end

  let(:row) { CSV.parse(csv_file, headers: true).first }

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:update)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'performs the job' do
    job.perform_now

    expect(described_class::JobItem)
      .to have_received(:new).with(druid:, index: 2, job:, row:)

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated source ID')
    expect(Sdr::Repository).to have_received(:update) do |args|
      expect(args[:cocina_object].identification.sourceId).to eq new_source_id
      expect(args[:user_name]).to eq bulk_action.user.sunetid
      expect(args[:description]).to eq 'Updated source ID'
    end
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user is not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the source id' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
    end
  end

  context 'when validation fails' do
    let(:new_source_id) { 'invalid' }

    it 'does not update the source id' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include 'Source is invalid'

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
    end
  end

  context 'when unchanged' do
    let(:new_source_id) { source_id }

    it 'does not update the source id' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include 'No changes to source ID'

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 0
      expect(bulk_action.druid_count_success).to eq 1
    end
  end
end
