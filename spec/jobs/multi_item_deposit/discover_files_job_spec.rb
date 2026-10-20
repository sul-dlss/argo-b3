# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DiscoverFilesJob do
  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:mount_path) { Dir.mktmpdir }
  let(:folder_path) { File.join(mount_path, 'item1') }
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, mount_path:) }
  let(:item_deposit_action) do
    create(:item_deposit_action, multi_item_deposit_action:, druid:, path: 'item1',
                                 discovery_errors: ['Old error'], discovery_warnings: ['Old warning'])
  end
  let(:effective_groups) { ['workgroup:depositors'] }
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book, admin_policy_id: apo_druid)
  end
  let(:version_service) do
    version_service_double(open?: false, openable?: true, closeable?: true, version: 2)
  end

  before do
    create(:permission, :edit, workgroup: 'workgroup:depositors', target_druid: apo_druid)
    FileUtils.mkdir_p(File.join(folder_path, 'folder'))
    File.write(File.join(folder_path, 'file1.txt'), 'file one')
    File.write(File.join(folder_path, 'folder/file2.txt'), 'file two!')
    File.write(File.join(folder_path, '.DS_Store'), 'ignored')
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    allow(Sdr::VersionService).to receive(:new).and_return(version_service)
  end

  after do
    FileUtils.rm_rf(mount_path)
  end

  def perform
    job.perform(item_deposit_action:, effective_groups:)
    item_deposit_action.reload
  end

  context 'when there are no errors or warnings' do
    it 'records the files in a new mutable Content' do
      perform

      expect(item_deposit_action).to have_attributes(discovery_errors: [], discovery_warnings: [],
                                                     initial_version: false, content_type: 'book')
      expect(item_deposit_action.content).to have_attributes(druid:, lock: 'abc123', immutable: false,
                                                             mount_state: 'discovery_not_in_progress')
      expect(item_deposit_action.content.content_file_binaries.find_by(filepath: 'folder/file2.txt'))
        .to have_attributes(file_location: 'mount', mount_path: folder_path, size: 9, mime_type: 'text/plain')
      expect(item_deposit_action.content.content_file_binaries.pluck(:filepath))
        .to contain_exactly('file1.txt', 'folder/file2.txt')
      expect(Sdr::Repository).to have_received(:find).with(druid:)
      expect(Sdr::VersionService).to have_received(:new).with(druid:)
    end
  end

  context 'when the object is an initial version' do
    let(:version_service) { version_service_double(open?: true, closeable?: true, version: 1) }

    it 'sets initial_version' do
      expect(perform.initial_version).to be true
    end
  end

  context 'when the folder does not exist' do
    let(:folder_path) { File.join(mount_path, 'other') }

    it 'records an error and does not create a Content' do
      perform

      expect(item_deposit_action.discovery_errors).to eq(['Folder not found: item1'])
      expect(item_deposit_action.content).to be_nil
    end
  end

  context 'when the folder has only ignored files' do
    before do
      FileUtils.rm_rf(File.join(folder_path, 'folder'))
      FileUtils.rm(File.join(folder_path, 'file1.txt'))
    end

    it 'records an error' do
      expect(perform.discovery_errors).to eq(['No files found in folder: item1'])
    end
  end

  context 'when files are larger than 4 TB' do
    before do
      allow(File).to receive(:size).and_call_original
      allow(File).to receive(:size).with(File.join(folder_path, 'file1.txt')).and_return(4_000_000_000_001)
      allow(File).to receive(:size).with(File.join(folder_path, 'folder/file2.txt')).and_return(4_000_000_000_001)
    end

    it 'records a single error for the files' do
      perform

      expect(item_deposit_action.discovery_errors).to eq(['Files larger than 4 TB: file1.txt, folder/file2.txt'])
      expect(item_deposit_action.content).to be_nil
    end
  end

  context 'when filepaths contain invalid UTF-8 bytes' do
    let!(:existing_content) { create(:content, :mutable, druid:, lock: 'abc123') }
    let(:invalid_filepaths) { ["bad\xFF.txt", "folder\xFE/file.txt"] }

    before do
      create(:content_file_binary, content: existing_content, filepath: 'existing.txt')
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with('**/*', File::FNM_DOTMATCH, base: folder_path)
                                  .and_return(['file1.txt', *invalid_filepaths])
      allow(File).to receive(:file?).and_call_original
      invalid_filepaths.each do |filepath|
        allow(File).to receive(:file?).with(File.join(folder_path, filepath)).and_return(true)
      end
      allow(Honeybadger).to receive(:notify)
    end

    it 'reports invalid filename bytes without replacing existing content' do
      expect { perform }.not_to change(Content, :count)

      expect(item_deposit_action.discovery_errors)
        .to eq(['Filepaths contain invalid UTF-8 bytes: "bad\\xFF.txt", "folder\\xFE/file.txt"'])
      expect(item_deposit_action.content).to be_nil
      expect(Content.exists?(existing_content.id)).to be true
      expect(existing_content.content_file_binaries.pluck(:filepath)).to eq(['existing.txt'])
      expect(Honeybadger).not_to have_received(:notify)
    end
  end

  context 'when there are empty files and folders' do
    before do
      File.write(File.join(folder_path, 'zero2.txt'), '')
      File.write(File.join(folder_path, 'folder/zero1.txt'), '')
      FileUtils.mkdir_p(File.join(folder_path, 'empty/nested'))
      FileUtils.mkdir_p(File.join(folder_path, 'only_ignored'))
      File.write(File.join(folder_path, 'only_ignored/Thumbs.db'), 'ignored')
      FileUtils.mkdir_p(File.join(folder_path, '__MACOSX'))
    end

    it 'records a single warning for each kind of problem and still creates the Content' do
      perform

      expect(item_deposit_action.discovery_errors).to eq([])
      expect(item_deposit_action.discovery_warnings).to eq(['Empty files: folder/zero1.txt, zero2.txt',
                                                            'Empty folders: empty, only_ignored'])
      expect(item_deposit_action.content.content_file_binaries.count).to eq(4)
    end
  end

  context 'when the object is not found' do
    before do
      allow(Sdr::Repository).to receive(:find).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'records an error' do
      expect(perform.discovery_errors).to eq(['Object not found'])
    end
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid, admin_policy_id: apo_druid) }

    it 'records a not an Item error' do
      expect(perform.discovery_errors).to eq(['Not an Item'])
    end
  end

  context 'when the object is an APO' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid, admin_policy_id: apo_druid) }

    it 'records a not an Item error' do
      expect(perform.discovery_errors).to eq(['Not an Item'])
    end
  end

  context 'when the object is an agreement' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.agreement, admin_policy_id: apo_druid)
    end

    it 'records a not an Item error' do
      expect(perform.discovery_errors).to eq(['Not an Item'])
    end
  end

  context 'when the object is a virtual object' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image, admin_policy_id: apo_druid)
        .new(structural: { hasMemberOrders: [{ members: ['druid:dd222ff3344'] }] })
    end

    it 'records a not an Item error' do
      expect(perform.discovery_errors).to eq(['Not an Item'])
    end
  end

  context 'when the effective groups cannot update the object' do
    let(:effective_groups) { ['workgroup:other'] }

    it 'records an error and skips the version checks' do
      expect(perform.discovery_errors).to eq(['Not authorized to update'])
      expect(Sdr::VersionService).not_to have_received(:new)
    end
  end

  context 'when the object is closed and not openable' do
    let(:version_service) { version_service_double(open?: false, openable?: false, version: 2) }

    it 'records a warning' do
      expect(perform.discovery_warnings).to eq(['A new version cannot be opened for this object'])
    end
  end

  context 'when the object is open and not closeable' do
    let(:version_service) { version_service_double(open?: true, closeable?: false, version: 2) }

    it 'records a warning' do
      expect(perform.discovery_warnings).to eq(['The open version cannot be closed for this object'])
    end
  end

  context 'when there is an existing mutable Content that is staging' do
    let!(:existing_content) do
      create(:content, :mutable, druid:, lock: 'abc123', staging_state: 'staging')
    end

    it 'records an error and keeps the existing Content' do
      perform

      expect(item_deposit_action.discovery_errors).to eq(['Files are being staged or discovered for this object'])
      expect(Content.exists?(existing_content.id)).to be true
    end
  end

  context 'when there is an existing mutable Content that is not in progress' do
    let!(:existing_content) { create(:content, :mutable, druid:, lock: 'abc123') }

    it 'discards it, records a warning, and creates a new Content' do
      perform

      expect(item_deposit_action.discovery_warnings).to eq(['Discarded in-progress file edits'])
      expect(Content.exists?(existing_content.id)).to be false
      expect(item_deposit_action.content.content_file_binaries.count).to eq(2)
    end
  end

  context 'when there is an existing mutable Content and other errors' do
    let!(:existing_content) { create(:content, :mutable, druid:, lock: 'abc123') }
    let(:folder_path) { File.join(mount_path, 'other') }

    it 'keeps the existing Content' do
      perform

      expect(item_deposit_action.discovery_errors).to eq(['Folder not found: item1'])
      expect(Content.exists?(existing_content.id)).to be true
    end
  end

  context 'when an unexpected error occurs' do
    let(:error) { StandardError.new('Boom') }

    before do
      allow(Contents::MountDiscoverer).to receive(:call).and_raise(error)
      allow(Honeybadger).to receive(:notify)
    end

    it 'records an error, notifies Honeybadger, and destroys the partially built Content' do
      expect { perform }.not_to change(Content, :count)

      expect(item_deposit_action.discovery_errors)
        .to eq(['An unexpected error occurred during discovery. Contact SDR support for assistance.'])
      expect(item_deposit_action.content).to be_nil
      expect(Honeybadger).to have_received(:notify).with(error)
    end
  end
end
