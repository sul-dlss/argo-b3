# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DiscoveryForm do
  subject(:form) do
    described_class.new(manifest_source:, manifest_file:, manifest_csv:, file_location:, mount_path:)
  end

  let(:file_location) { 'mount' }
  let(:mount_directory) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }
  let(:mount_path) { mount_directory }
  let(:manifest_source) { 'upload' }
  let(:manifest_file) { Rack::Test::UploadedFile.new(csv_tempfile.path, 'text/csv') }
  let(:manifest_csv) { nil }
  let(:csv_tempfile) { Tempfile.new(['manifest', extension]).tap { |file| file.write(csv_string) && file.flush } }
  let(:extension) { '.csv' }
  let(:csv_string) { "druid,folder_name\nbc123df4567,folder1\n" }

  after do
    FileUtils.rm_rf(mount_directory)
  end

  context 'when the manifest is uploaded' do
    it 'normalizes the uploaded manifest' do
      expect(form).to be_valid
      expect(form.submitted_manifest_csv).to eq("druid,folder_name\ndruid:bc123df4567,folder1\n")
    end
  end

  context 'when the manifest was uploaded with an earlier submit' do
    let(:manifest_file) { nil }
    let(:manifest_csv) { "druid,folder_name\ndruid:cd234fg5678,folder2\n" }

    it 'uses the earlier manifest' do
      expect(form).to be_valid
      expect(form.submitted_manifest_csv).to eq("druid,folder_name\ndruid:cd234fg5678,folder2\n")
      expect(form.retainable_manifest_csv).to eq("druid,folder_name\ndruid:cd234fg5678,folder2\n")
    end
  end

  context 'when a manifest is uploaded to replace the earlier manifest' do
    let(:manifest_csv) { "druid,folder_name\ndruid:cd234fg5678,folder2\n" }

    it 'uses the new manifest' do
      expect(form).to be_valid
      expect(form.submitted_manifest_csv).to eq("druid,folder_name\ndruid:bc123df4567,folder1\n")
    end
  end

  context 'when the uploaded manifest is valid but the mount path is not' do
    let(:mount_path) { File.join(mount_directory, 'missing') }

    it 'retains the uploaded manifest' do
      expect(form).not_to be_valid
      expect(form.retainable_manifest_csv).to eq("druid,folder_name\ndruid:bc123df4567,folder1\n")
    end
  end

  context 'when the uploaded manifest is not valid' do
    let(:csv_string) { "druid,folder_name\nbc123df4567,../folder1\n" }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:manifest_file]).to eq(['Folders outside the mount path: ../folder1.'])
    end
  end

  context 'when the manifest is uploaded without a file' do
    let(:manifest_file) { nil }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:manifest_file]).to eq(["can't be blank"])
    end
  end

  context 'when the uploaded file cannot be read' do
    let(:extension) { '.txt' }

    it 'is not valid and does not retain the manifest' do
      expect(form).not_to be_valid
      expect(form.errors[:manifest_file]).to eq(['Unsupported upload file type'])
      expect(form.retainable_manifest_csv).to be_nil
    end
  end

  context 'when the manifest is included with the files' do
    let(:manifest_source) { 'mount' }

    before do
      File.write(File.join(mount_directory, 'manifest.csv'), "druid,folder_name\ncd234fg5678,folder2\n")
    end

    it 'normalizes the manifest from the mount path' do
      expect(form).to be_valid
      expect(form.submitted_manifest_csv).to eq("druid,folder_name\ndruid:cd234fg5678,folder2\n")
      expect(form.retainable_manifest_csv).to be_nil
    end
  end

  context 'when the manifest is included with the files but is missing' do
    let(:manifest_source) { 'mount' }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:manifest_source]).to eq(['manifest.csv not found in the mount path'])
    end
  end

  context 'when the manifest included with the files is not valid' do
    let(:manifest_source) { 'mount' }

    before do
      File.write(File.join(mount_directory, 'manifest.csv'), "druid,filename\ncd234fg5678,file.tif\n")
    end

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:manifest_source]).to eq(['Missing columns: folder_name.'])
    end
  end

  context 'when the manifest included with the files cannot be read' do
    let(:manifest_source) { 'mount' }

    before do
      File.write(File.join(mount_directory, 'manifest.csv'), "druid,folder_name\nbc123df4567,\"folder1\n")
    end

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:manifest_source]).to eq(['Unclosed quoted field in line 2.'])
    end
  end

  context 'when no manifest source is given' do
    subject(:form) { described_class.new }

    it 'defaults to uploading the manifest' do
      expect(form.manifest_source).to eq('upload')
    end
  end

  context 'when the manifest source is not supported' do
    let(:manifest_source) { 'other' }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:manifest_source]).to be_present
    end
  end

  context 'when the files are on a mount without a mount path' do
    let(:mount_path) { ' ' }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:mount_path]).to eq(["can't be blank"])
    end
  end

  context 'when the mount path does not exist' do
    let(:mount_path) { File.join(mount_directory, 'missing') }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:mount_path]).to eq(['does not exist'])
    end
  end

  context 'when the mount path is outside the mount locations' do
    let(:mount_path) { Rails.root.join('app').to_s }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:mount_path]).to eq(['must be within a mount location'])
    end
  end

  context 'when the file location is not supported' do
    let(:file_location) { 'other' }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:file_location]).to be_present
    end
  end

  describe '#multi_item_deposit_action_attributes' do
    it 'includes the manifest source and normalized manifest' do
      expect(form.multi_item_deposit_action_attributes)
        .to eq(description: nil, file_location: 'mount', mount_path: mount_directory, manifest_source: 'upload',
               manifest_csv: "druid,folder_name\ndruid:bc123df4567,folder1\n")
    end
  end

  describe '#unsaved_manifest_csv?' do
    let(:multi_item_deposit_action) { build(:multi_item_deposit_action, manifest_csv: saved_manifest_csv) }

    context 'when the uploaded manifest is not saved' do
      let(:saved_manifest_csv) { "druid,folder_name\ndruid:cd234fg5678,folder2\n" }

      it 'is true' do
        expect(form.unsaved_manifest_csv?(multi_item_deposit_action)).to be true
      end
    end

    context 'when the uploaded manifest is saved' do
      let(:saved_manifest_csv) { "druid,folder_name\ndruid:bc123df4567,folder1\n" }

      it 'is false' do
        expect(form.unsaved_manifest_csv?(multi_item_deposit_action)).to be false
      end
    end
  end

  describe '.from_model' do
    subject(:form) { described_class.from_model(multi_item_deposit_action) }

    let(:multi_item_deposit_action) do
      build(:multi_item_deposit_action, manifest_source: 'mount', manifest_csv: "druid,folder_name\n")
    end

    it 'has the saved manifest source and manifest' do
      expect(form).to have_attributes(manifest_source: 'mount', manifest_csv: "druid,folder_name\n")
    end
  end
end
