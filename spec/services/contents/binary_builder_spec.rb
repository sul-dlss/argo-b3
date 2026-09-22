# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::BinaryBuilder do
  subject(:call) { described_class.call(content:, files:, paths:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:uploaded_file) { fixture_file_upload('dropzone_upload.txt', 'text/plain') }
  let(:files) { { '0' => uploaded_file } }
  let(:paths) { { '0' => 'folder/dropzone_upload.txt' } }

  describe '.call' do
    it 'creates an attached binary for an uploaded file' do
      call

      content_file_binary = content.content_file_binaries.sole
      expect(content_file_binary).to have_attributes(filepath: 'folder/dropzone_upload.txt',
                                                     file_location: 'attached', size: uploaded_file.size)
      expect(content_file_binary.file).to be_attached
      expect(content_file_binary.file.filename.to_s).to eq('dropzone_upload.txt')
    end

    it 'does not create file sets or files' do
      call

      expect(content.content_file_sets).to be_empty
      expect(content.content_files).to be_empty
    end

    context 'when multiple files are uploaded' do
      let(:other_uploaded_file) { fixture_file_upload('dropzone_upload.txt', 'text/plain') }
      let(:files) { { '0' => uploaded_file, '1' => other_uploaded_file } }
      let(:paths) { { '0' => 'folder/dropzone_upload.txt', '1' => 'folder/other_upload.txt' } }

      it 'creates a binary for each' do
        call

        expect(content.content_file_binaries.pluck(:filepath))
          .to contain_exactly('folder/dropzone_upload.txt', 'folder/other_upload.txt')
      end
    end

    context 'when the same filepath is uploaded twice' do
      let(:other_uploaded_file) { fixture_file_upload('dropzone_upload.txt', 'text/plain') }
      let(:files) { { '0' => uploaded_file, '1' => other_uploaded_file } }
      let(:paths) { { '0' => 'folder/dropzone_upload.txt', '1' => 'folder/dropzone_upload.txt' } }

      it 'creates a single binary' do
        call

        expect(content.content_file_binaries.sole.filepath).to eq('folder/dropzone_upload.txt')
      end
    end

    context 'when a binary already exists for the filepath' do
      let!(:content_file_binary) do
        create(:content_file_binary, content:, filepath: 'folder/dropzone_upload.txt', file_location: 'deposited',
                                     size: 123, md5_digest: 'existing-md5', sha1_digest: 'existing-sha1',
                                     mime_type: 'image/tiff')
      end

      it 'reuses the binary and replaces its attachment metadata' do
        expect { call }.not_to change(ContentFileBinary, :count)

        expect(content_file_binary.reload).to have_attributes(file_location: 'attached', size: uploaded_file.size,
                                                              md5_digest: nil, sha1_digest: nil, mime_type: nil)
        expect(content_file_binary.file).to be_attached
      end
    end

    context 'when the filepath should be ignored' do
      let(:paths) { { '0' => 'folder/._dropzone_upload.txt' } }

      it 'does not create a binary' do
        expect { call }.not_to change(ContentFileBinary, :count)
        expect(content.content_file_binaries).to be_empty
      end
    end

    context 'when the filepath is missing' do
      let(:paths) { {} }

      it 'does not create a binary' do
        expect { call }.not_to change(ContentFileBinary, :count)
        expect(content.content_file_binaries).to be_empty
      end
    end
  end
end
