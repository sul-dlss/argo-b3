# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ExportChecksumReportJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bare_druid) { 'bc123df4567' }
  let(:bulk_action) { create(:bulk_action, action_type: 'export_checksum_report') }
  let(:log) { StringIO.new }

  let(:checksum_response) do
    [
      {
        'filename' => 'bc123df4567_img_1.tif',
        'md5' => 'ffc0cc90e4215e0a3d822b04a8eab980',
        'sha1' => 'd2703add746d7b6e2e5f8a73ef7c06b087b3fae5',
        'sha256' => '6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f',
        'filesize' => '4403882'
      },
      {
        'filename' => 'bc123df4567_img_2.tif',
        'md5' => 'ggc0cc90e4215e0a3d822b04a8eab991',
        'sha1' => 'e3703add746d7b6e2e5f8a73ef7c06b087b3faf6',
        'sha256' => '7c66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527033g',
        'filesize' => '5503893'
      }
    ]
  end

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  before do
    create(:permission, :read_unrestricted, workgroup: bulk_action.user.groups.first)

    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Preservation::Client.objects).to receive(:checksum).with(druid:).and_return(checksum_response)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'exports checksums to a CSV file' do
    job.perform_now

    expect(Preservation::Client.objects).to have_received(:checksum).with(druid:)

    expect(File).to exist(bulk_action.export_filepath(:checksum_report))
    expect(File.read(bulk_action.export_filepath(:checksum_report))).to eq(
      <<~CSV
        druid,filename,md5,sha1,sha256,size
        #{bare_druid},bc123df4567_img_1.tif,ffc0cc90e4215e0a3d822b04a8eab980,d2703add746d7b6e2e5f8a73ef7c06b087b3fae5,6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f,4403882
        #{bare_druid},bc123df4567_img_2.tif,ggc0cc90e4215e0a3d822b04a8eab991,e3703add746d7b6e2e5f8a73ef7c06b087b3faf6,7c66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527033g,5503893
      CSV
    )

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when not authorized to read the object' do
    before do
      allow(described_class::JobItem).to receive(:new).and_wrap_original do |original, **args|
        original.call(**args).tap { |job_item| allow(job_item).to receive(:check_read_ability?).and_return(false) }
      end
    end

    it 'does not call the preservation catalog API' do
      job.perform_now

      expect(Preservation::Client.objects).not_to have_received(:checksum)
    end
  end

  context 'when the object is not found in the preservation catalog' do
    before do
      allow(Preservation::Client.objects).to receive(:checksum)
        .with(druid:).and_raise(Preservation::Client::NotFoundError)
    end

    it 'records the object as not found and counts it as a failure' do
      job.perform_now

      expect(File.read(bulk_action.export_filepath(:checksum_report))).to eq(
        <<~CSV
          druid,filename,md5,sha1,sha256,size
          #{bare_druid},object not found or not fully accessioned
        CSV
      )

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end
end
