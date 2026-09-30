# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportStructuralMetadataJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:, close_version:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bare_druid) { 'bc123df4567' }
  let(:close_version) { false }
  let(:headers) do
    'druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,' \
      'rights_download,rights_location,mimetype,role'
  end

  let(:csv_file) do
    <<~CSV
      druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
      #{druid},Page 1,page,1,bc123df4567_00_0001.tif,bc123df4567_00_0001.tif,no,no,yes,world,world,,image/tiff,
      #{druid},Page 1,page,1,bc123df4567_05_0001.jp2,bc123df4567_05_0001.jp2,yes,yes,yes,world,world,,image/jp2,
    CSV
  end
  let(:rows) { CSV.parse(csv_file, headers: true).each.to_a }
  let(:line_numbers) { [2, 3] }

  let(:cocina_object) do
    build(:dro_with_metadata, id: druid).new(structural:, access: { view: 'world', download: 'world' })
  end

  let(:structural) do
    {
      contains: [
        {
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-e43590ae-abf9-4a5c-88f2-a8627969dc23',
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [
              build_file(filename: 'bc123df4567_00_0001.tif', mime_type: 'image/tiff',
                         external_identifier: 'https://cocina.sul.stanford.edu/file/bc123df4567-de24d694-2fe8-41a5-9113-ae6adf4506fd'),
              build_file(filename: 'bc123df4567_05_0001.jp2', mime_type: 'image/jp2',
                         external_identifier: 'https://cocina.sul.stanford.edu/file/bc123df4567-92db9253-19b7-4092-b472-6e73f3c2251e')
            ]
          }
        }
      ]
    }
  end

  let(:bulk_action) { create(:bulk_action) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 2, job:, rows:, line_numbers:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
      allow(job_item).to receive(:close_version_if_needed!)
    end
  end

  def build_file(filename:, mime_type:, external_identifier:, access: { view: 'world', download: 'world' })
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: external_identifier,
      label: filename,
      filename:,
      size: 22_454_748,
      version: 1,
      hasMimeType: mime_type,
      hasMessageDigests: [
        { type: 'sha1', digest: 'ff66b3b3dc3ef733d39e949549791ff78754871b' },
        { type: 'md5', digest: 'b6ce12a1dd5db09f10b51659c83f90a3' }
      ],
      access:,
      administrative: { publish: false, sdrPreserve: true, shelve: false }
    }
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:update)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'performs the job' do
    job.perform_now

    expect(described_class::JobItem).to have_received(:new).with(druid:, index: 2, job:, rows:, line_numbers:)

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated structural metadata')
    expect(Sdr::Repository).to have_received(:update) do |args|
      file_set = args[:cocina_object].structural.contains.first
      expect(file_set.type).to eq Cocina::Models::FileSetType.page
      expect(file_set.label).to eq 'Page 1'
      expect(file_set.structural.contains.map { |file| file.administrative.publish }).to eq [false, true]
      expect(args[:user_name]).to eq bulk_action.user.sunetid
      expect(args[:description]).to eq 'Updated structural metadata'
    end
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(log.string).to include "line 2\t#{druid}\tSuccess: Structural metadata updated"

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user is not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the structural metadata' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
    end
  end

  context 'when the object is not a DRO' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'does not update the structural metadata' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include "line 2\t#{druid}\tError: Not an item"

      expect(bulk_action.reload.druid_count_fail).to eq 1
    end
  end

  context 'when the provided structural is invalid' do
    # The structure update will fail for this cocina object since it has to have matching files.
    let(:cocina_object) { build(:dro_with_metadata, id: druid) }

    it 'records a failure' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include "line 2\t#{druid}\tError: On row 2 found bc123df4567_00_0001.tif, " \
                                    'which appears to be a new file; On row 3 found bc123df4567_05_0001.jp2, ' \
                                    'which appears to be a new file'

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when the updated object fails validation' do
    # Files cannot have world access when the object is dark.
    let(:cocina_object) { build(:dro_with_metadata, id: druid).new(structural:) }
    let(:structural) do
      {
        contains: [
          {
            type: Cocina::Models::FileSetType.image,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-e43590ae-abf9-4a5c-88f2-a8627969dc23',
            label: 'Image 1',
            version: 1,
            structural: {
              contains: [
                build_file(filename: 'bc123df4567_00_0001.tif', mime_type: 'image/tiff',
                           external_identifier: 'https://cocina.sul.stanford.edu/file/bc123df4567-de24d694-2fe8-41a5-9113-ae6adf4506fd',
                           access: { view: 'dark', download: 'none' }),
                build_file(filename: 'bc123df4567_05_0001.jp2', mime_type: 'image/jp2',
                           external_identifier: 'https://cocina.sul.stanford.edu/file/bc123df4567-92db9253-19b7-4092-b472-6e73f3c2251e',
                           access: { view: 'dark', download: 'none' })
              ]
            }
          }
        ]
      }
    end

    it 'records a failure' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include "line 2\t#{druid}\tError: Validation failed (Not all files have dark access"

      expect(bulk_action.reload.druid_count_fail).to eq 1
    end
  end

  context 'when the structural is unchanged' do
    let(:csv_file) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{druid},Image 1,image,1,bc123df4567_00_0001.tif,bc123df4567_00_0001.tif,no,no,yes,world,world,,image/tiff,
        #{druid},Image 1,image,1,bc123df4567_05_0001.jp2,bc123df4567_05_0001.jp2,no,no,yes,world,world,,image/jp2,
      CSV
    end

    it 'does not update the structural metadata' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include "line 2\t#{druid}\tSuccess: Structural metadata unchanged"

      expect(bulk_action.reload.druid_count_success).to eq 1
    end
  end

  context 'with multiple druids with interleaved rows' do
    let(:other_druid) { 'druid:df987gh6543' }
    let(:other_object_client) { instance_double(Dor::Services::Client::Object) }
    let(:csv_file) do
      <<~CSV
        #{headers}
        #{druid},Page 1,page,1,bc123df4567_00_0001.tif,bc123df4567_00_0001.tif,no,no,yes,world,world,,image/tiff,
        #{other_druid},Page 1,page,1,df987gh6543_00_0001.tif,df987gh6543_00_0001.tif,no,no,yes,world,world,,image/tiff,
        #{druid},Page 1,page,1,#{jp2_filename},#{jp2_filename},yes,yes,yes,world,world,,image/jp2,
      CSV
    end
    let(:jp2_filename) { 'bc123df4567_05_0001.jp2' }
    let(:rows) { CSV.parse(csv_file, headers: true).each.to_a.values_at(0, 2) }
    let(:line_numbers) { [2, 4] }

    before do
      allow(described_class::JobItem).to receive(:new).and_call_original
      allow(described_class::JobItem).to receive(:new).with(hash_including(druid:)).and_return(job_item)
      allow(Dor::Services::Client).to receive(:object).with(other_druid).and_return(other_object_client)
      allow(other_object_client).to receive(:find).and_raise(Dor::Services::Client::NotFoundResponse)
    end

    it 'groups the rows by druid' do
      job.perform_now

      expect(described_class::JobItem).to have_received(:new).with(druid:, index: 2, job:, rows:, line_numbers:)
      expect(described_class::JobItem).to have_received(:new)
        .with(druid: other_druid, index: 3, job:, rows: [CSV.parse(csv_file, headers: true)[1]], line_numbers: [3])
      expect(Sdr::Repository).to have_received(:update).once

      expect(log.string).to include "line 2\t#{druid}\tSuccess: Structural metadata updated"
      expect(log.string).to include "line 3\t#{other_druid}\tError: Object not found"

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
    end

    context 'when a row has an error' do
      let(:jp2_filename) { 'bc123df4567_05_0002.jp2' }

      it 'reports the spreadsheet line number of the row' do
        job.perform_now

        expect(Sdr::Repository).not_to have_received(:update)
        expect(log.string).to include "line 2\t#{druid}\tError: On row 4 found #{jp2_filename}, " \
                                      'which appears to be a new file'
      end
    end
  end

  context 'when closing the version' do
    let(:close_version) { true }
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(structural:, version: 2, access: { view: 'world', download: 'world' })
    end

    before do
      allow(job_item).to receive(:close_version_if_needed!).and_call_original
      allow(Sdr::VersionService).to receive_messages(closed?: false, closeable?: true)
      allow(Sdr::VersionService).to receive(:close)
    end

    it 'closes the version' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update)
      expect(Sdr::VersionService).to have_received(:close).with(druid:)
      expect(log.string).to include 'Closed version'
    end
  end

  context 'when the CSV has an invalid rights value' do
    let(:csv_file) do
      <<~CSV
        #{headers}
        #{druid},Page 1,page,1,bc123df4567_00_0001.tif,bc123df4567_00_0001.tif,no,no,yes,public,world,,image/tiff,
      CSV
    end
    let(:line_numbers) { [2] }

    it 'records a failure' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(log.string).to include "line 2\t#{druid}\tError: Validation failed (When validating DROWithMetadata: " \
                                    '"public" is not one of "dark"'

      expect(bulk_action.reload.druid_count_fail).to eq 1
    end
  end

  context 'when updating the object fails' do
    before do
      allow(Sdr::Repository).to receive(:update).and_raise(Sdr::Repository::Error, 'Updating failed: boom')
    end

    it 'records a failure' do
      job.perform_now

      expect(job_item).not_to have_received(:close_version_if_needed!)

      expect(log.string).to include "line 2\t#{druid}\tError: Sdr::Repository::Error Updating failed: boom"

      expect(bulk_action.reload.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when the druid column is missing' do
    let(:csv_file) do
      <<~CSV
        x#{headers}
        #{druid},Page 1,page,1,bc123df4567_00_0001.tif,bc123df4567_00_0001.tif,no,no,yes,world,world,,image/tiff,
        #{druid},Page 1,page,1,bc123df4567_05_0001.jp2,bc123df4567_05_0001.jp2,yes,yes,yes,world,world,,image/jp2,
      CSV
    end

    it 'records failures for all rows' do
      job.perform_now

      expect(described_class::JobItem).not_to have_received(:new)
      expect(log.string).to include 'Column "druid" not found'

      expect(bulk_action.reload.druid_count_total).to eq 2
      expect(bulk_action.druid_count_fail).to eq 2
    end
  end

  context 'when the CSV only has a header row' do
    let(:csv_file) { "#{headers}\n" }

    it 'does nothing' do
      job.perform_now

      expect(described_class::JobItem).not_to have_received(:new)
      expect(log.string).not_to include 'Error'

      expect(bulk_action.reload.druid_count_total).to eq 0
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 0
    end
  end

  context 'when a row has a blank druid' do
    let(:csv_file) do
      <<~CSV
        #{headers}
        #{druid},Page 1,page,1,bc123df4567_00_0001.tif,bc123df4567_00_0001.tif,no,no,yes,world,world,,image/tiff,
        ,Page 1,page,1,bc123df4567_05_0001.jp2,bc123df4567_05_0001.jp2,yes,yes,yes,world,world,,image/jp2,
        #{druid},Page 1,page,1,bc123df4567_05_0001.jp2,bc123df4567_05_0001.jp2,yes,yes,yes,world,world,,image/jp2,
      CSV
    end
    let(:rows) { CSV.parse(csv_file, headers: true).each.to_a.values_at(0, 2) }
    let(:line_numbers) { [2, 4] }

    it 'records a failure for the row and processes the other rows' do
      job.perform_now

      expect(described_class::JobItem).to have_received(:new).once
      expect(described_class::JobItem).to have_received(:new).with(druid:, index: 2, job:, rows:, line_numbers:)
      expect(Sdr::Repository).to have_received(:update).once

      expect(log.string).to include "line 3\t\tError: Missing druid"

      expect(bulk_action.reload.druid_count_total).to eq 2
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end
end
