# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::MountDiscoverer do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:mount_path) { Dir.mktmpdir }

  before do
    FileUtils.mkdir_p(File.join(mount_path, 'folder'))
    File.write(File.join(mount_path, 'file1.txt'), 'file one')
    File.write(File.join(mount_path, 'folder/file2.txt'), 'file two!')
    File.write(File.join(mount_path, '._file1.txt'), 'ignored')
    File.write(File.join(mount_path, 'folder/.DS_Store'), 'ignored')
  end

  after do
    FileUtils.rm_rf(mount_path)
  end

  describe '.filepaths' do
    it 'returns the relative filepaths of the files that are not ignored' do
      expect(described_class.filepaths(mount_path:)).to contain_exactly('file1.txt', 'folder/file2.txt')
    end
  end

  describe '.call' do
    it 'creates mount binaries for the files on the mount, skipping ignored files' do
      described_class.call(content:, mount_path:)

      expect(content.content_file_binaries.pluck(:filepath)).to contain_exactly('file1.txt', 'folder/file2.txt')
      expect(content.content_file_binaries.find_by(filepath: 'file1.txt'))
        .to have_attributes(file_location: 'mount', mount_path:, size: 8, mime_type: 'text/plain')
      expect(content.content_file_binaries.find_by(filepath: 'folder/file2.txt'))
        .to have_attributes(file_location: 'mount', mount_path:, size: 9, mime_type: 'text/plain')
    end

    context 'when a binary already exists for the filepath' do
      let!(:content_file_binary) do
        create(:content_file_binary, content:, filepath: 'file1.txt', file_location: 'deposited',
                                     size: 123, md5_digest: 'existing-md5', sha1_digest: 'existing-sha1',
                                     mime_type: 'image/tiff')
      end

      it 'reuses the binary and replaces its metadata' do
        expect { described_class.call(content:, mount_path:) }.to change(ContentFileBinary, :count).by(1)

        expect(content_file_binary.reload).to have_attributes(file_location: 'mount', mount_path:, size: 8,
                                                              mime_type: 'text/plain',
                                                              md5_digest: nil, sha1_digest: nil)
      end
    end
  end
end
