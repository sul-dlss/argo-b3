# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::DownloadFilesJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) do
    create(:bulk_action, action_type: 'download_files', user:, created_at: Time.zone.parse('2026-11-16 10:00 PST'))
  end
  let(:user) { create(:user, :reader) }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }
  let(:content) { create(:content, druid:, lock: 'abc123') }
  let(:file_set) { create(:content_file_set, content:) }
  let(:objects_client) { instance_double(Preservation::Client::Objects) }
  let(:stacks_url) { "#{Settings.stacks.file_url}/#{druid}/image2.tif" }
  let(:zip_filepath) { bulk_action.filepath_for(filename: 'bc123df4567.zip') }
  let(:log) { StringIO.new }

  def create_content_file(filepath:, size:, position:, preserve: true, shelve: true)
    binary = create(:content_file_binary, content:, filepath:, size:)
    create(:content_file, content_file_set: file_set, content_file_binary: binary, position:, preserve:, shelve:)
  end

  def zip_entries
    Zip::File.open(zip_filepath) { |zip| zip.entries.to_h { |entry| [entry.name, entry.get_input_stream.read] } }
  end

  before do
    create_content_file(filepath: 'folder1/image1.tif', size: 9, position: 1)
    create_content_file(filepath: 'image2.tif', size: 6, position: 2, preserve: false)
    create_content_file(filepath: 'image3.tif', size: 4, position: 3, preserve: false, shelve: false)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Preservation::Client).to receive(:objects).and_return(objects_client)
    allow(objects_client).to receive(:content_to_file) do |filepath:, destination_filepath:, **|
      raise Preservation::Client::NotFoundError unless filepath == 'folder1/image1.tif'

      File.write(destination_filepath, 'preserved')
    end
    stub_request(:get, stacks_url).to_return(status: 200, body: 'stacks')
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'zips the available files' do
    job.perform_now

    expect(zip_entries).to eq('folder1/image1.tif' => 'preserved', 'image2.tif' => 'stacks')
    expect(bulk_action.reload).to have_attributes(druid_count_success: 1, druid_count_fail: 0, status: 'completed')
    expect(bulk_action.existing_exports.map(&:filename)).to eq(['bc123df4567.zip'])
    expect(log.string).to include("#{druid}\tSuccess: Zipped 2 files")
    expect(log.string).to include('This bulk action and its files will be deleted after 2026-11-23 10:00:00 PT.')
  end

  context 'when a file does not have the expected size' do
    before do
      stub_request(:get, stacks_url).to_return(status: 200, body: 'too long')
    end

    it 'zips the other files and logs the file' do
      job.perform_now

      expect(zip_entries).to eq('folder1/image1.tif' => 'preserved')
      expect(bulk_action.reload).to have_attributes(druid_count_success: 0, druid_count_fail: 1)
      expect(log.string).to include(
        "#{druid}\tError: Could not download image2.tif: expected 6 bytes, but got 8"
      )
      expect(log.string).to include("#{druid}\tError: Zipped 1 of 2 files")
    end
  end

  context 'when a file is not found' do
    before do
      allow(objects_client).to receive(:content_to_file).and_raise(Preservation::Client::NotFoundError)
      stub_request(:get, "#{Settings.stacks.file_url}/#{druid}/folder1/image1.tif").to_return(status: 404)
    end

    it 'zips the other files and logs the file' do
      job.perform_now

      expect(zip_entries).to eq('image2.tif' => 'stacks')
      expect(log.string).to include("#{druid}\tError: Could not download folder1/image1.tif: " \
                                    "Stacks returned 404 for #{druid} (folder1/image1.tif)")
    end
  end

  context 'when files of different Resources share a filepath' do
    before do
      other_file_set = create(:content_file_set, content:, position: 2)
      binary = content.content_file_binaries.find_by(filepath: 'image2.tif')
      create(:content_file, content_file_set: other_file_set, content_file_binary: binary, preserve: false)
    end

    it 'zips the file once' do
      job.perform_now

      expect(zip_entries).to eq('folder1/image1.tif' => 'preserved', 'image2.tif' => 'stacks')
      expect(a_request(:get, stacks_url)).to have_been_made.once
    end
  end

  context 'when stacks fails' do
    before do
      stub_const('Sdr::StacksFile::RETRY_OPTIONS', Sdr::StacksFile::RETRY_OPTIONS.merge(interval: 0))
      stub_request(:get, stacks_url).to_return(status: 503)
      allow(Honeybadger).to receive(:notify)
    end

    it 'zips the other files and logs the failure' do
      job.perform_now

      expect(zip_entries).to eq('folder1/image1.tif' => 'preserved')
      expect(log.string).to include("#{druid}\tError: Could not download image2.tif: " \
                                    "Sdr::StacksFile::Error Stacks returned 503 for #{druid} (image2.tif)")
    end
  end

  context 'when the files are too large' do
    before do
      allow(Settings.bulk_actions).to receive(:download_files_max_size).and_return(14)
    end

    it 'does not zip the files' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include(
        "#{druid}\tError: The files total 15 Bytes, more than the 14 Bytes that can be downloaded"
      )
      expect(File).not_to exist(zip_filepath)
    end
  end

  context 'when cancelled while zipping' do
    before do
      allow(objects_client).to receive(:content_to_file) do |destination_filepath:, **|
        File.write(destination_filepath, 'preserved')
        BulkAction.find(bulk_action.id).cancelling!
      end
    end

    it 'cancels without a zip' do
      job.perform_now

      expect(bulk_action.reload.status).to eq('cancelled')
      expect(a_request(:get, stacks_url)).not_to have_been_made
      expect(Dir.glob(File.join(bulk_action.output_directory, '*.zip*'))).to be_empty
    end
  end

  context 'when the user lacks read permission' do
    let(:user) { create(:user) }

    it 'does not zip the files' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include("#{druid}\tError: Not authorized to read")
      expect(File).not_to exist(zip_filepath)
    end
  end
end
