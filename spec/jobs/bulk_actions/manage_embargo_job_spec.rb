# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ManageEmbargoJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:, close_version: false) }

  let(:druid) { 'druid:bc123df4567' }
  let(:release_date) { '2040-04-04' }
  let(:view) { 'world' }
  let(:download) { 'world' }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:bulk_action) { create(:bulk_action) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:log) { StringIO.new }

  let(:csv_file) do
    [
      'druid,release_date,view,download',
      [druid, release_date, view, download].join(',')
    ].join("\n")
  end

  let(:row) { CSV.parse(csv_file, headers: true).first }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 2, job:, row:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
      allow(job_item).to receive(:close_version_if_needed!)
    end
  end

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
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Created or updated embargo')
    expect(Sdr::Repository).to have_received(:update) do |args|
      embargo = args[:cocina_object].access.embargo
      expect(embargo.releaseDate).to eq DateTime.parse(release_date)
      expect(embargo.view).to eq view
      expect(embargo.download).to eq download
      expect(args[:user_name]).to eq bulk_action.user.sunetid
      expect(args[:description]).to eq 'Created or updated embargo'
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

    it 'does not update the embargo' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
    end
  end

  context 'when the object is not a DRO' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'does not update the embargo' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('Not an item')

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when the release_date is missing' do
    let(:csv_file) do
      [
        'druid,release_date,view,download',
        [druid, '', view, download].join(',')
      ].join("\n")
    end

    it 'does not update the embargo' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('Missing required value for "release_date"')

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when the release_date is invalid' do
    let(:release_date) { 'invalid-date' }

    it 'does not update the embargo' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('is not a valid date')

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when the view access is invalid' do
    let(:view) { 'nobody' }

    it 'does not update the embargo and reports the model error' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('is not valid')

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when the download access is invalid' do
    let(:download) { 'nobody' }

    it 'does not update the embargo and reports the model error' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('is not valid')

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when location access is invalid' do
    let(:csv_file) do
      [
        'druid,release_date,view,download,location',
        [druid, release_date, 'location-based', 'location-based', 'invalid-location'].join(',')
      ].join("\n")
    end

    it 'does not update the embargo and reports the model error' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include('is not valid')

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when download is location-based and location is provided' do
    let(:download) { 'location-based' }
    let(:csv_file) do
      [
        'druid,release_date,view,download,location',
        [druid, release_date, view, download, 'spec'].join(',')
      ].join("\n")
    end

    it 'sets the location on the embargo' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        embargo = args[:cocina_object].access.embargo
        expect(embargo.download).to eq 'location-based'
        expect(embargo.location).to eq 'spec'
      end
    end
  end
end
