# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::FileUpdater do
  subject(:call) { described_class.call(content:, cocina_object:, files:, paths:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) { build(:dro_with_metadata, id: content.druid) }
  let(:uploaded_file) { fixture_file_upload('dropzone_upload.txt', 'text/plain') }
  let(:files) { { '0' => uploaded_file } }
  let(:paths) { { '0' => 'folder/dropzone_upload.txt' } }

  describe '.call' do
    it 'creates a file set, binary, and file for an uploaded file' do
      call

      content_file_set = content.content_file_sets.sole
      expect(content_file_set).to have_attributes(file_set_type: 'object', label: '')

      content_file = content_file_set.content_files.sole
      expect(content_file).to have_attributes(label: '', preserve: true, publish: true, shelve: true,
                                              view: cocina_object.access.view,
                                              download: cocina_object.access.download,
                                              location: cocina_object.access.location)

      content_file_binary = content_file.content_file_binary
      expect(content_file_binary).to have_attributes(filepath: 'folder/dropzone_upload.txt',
                                                     file_location: 'attached', size: uploaded_file.size)
      expect(content_file_binary.file).to be_attached
      expect(content_file_binary.file.filename.to_s).to eq('dropzone_upload.txt')
    end

    context 'when the filepath should be ignored' do
      let(:paths) { { '0' => 'folder/._dropzone_upload.txt' } }

      it 'does not create file records' do
        expect { call }.not_to change(ContentFile, :count)
        expect(content.content_file_sets).to be_empty
        expect(content.content_file_binaries).to be_empty
      end
    end

    context 'when a binary already exists for the filepath' do
      let!(:content_file_binary) do
        create(:content_file_binary, content:, filepath: 'folder/dropzone_upload.txt', file_location: 'deposited',
                                     size: 123, md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
      end

      it 'reuses the binary and replaces its attachment metadata' do
        expect { call }.not_to change(ContentFileBinary, :count)

        expect(content.content_files.sole.content_file_binary).to eq(content_file_binary)
        expect(content_file_binary.reload).to have_attributes(file_location: 'attached', size: uploaded_file.size,
                                                              md5_digest: nil, sha1_digest: nil)
        expect(content_file_binary.file).to be_attached
      end
    end

    context 'when the object is embargoed' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(
          access: {
            view: 'citation-only',
            download: 'none',
            embargo: {
              releaseDate: DateTime.parse('2040-06-15T19:00:00Z'),
              view: 'stanford',
              download: 'stanford'
            }
          }
        )
      end

      it 'uses the embargo access settings' do
        call

        expect(content.content_files.sole).to have_attributes(view: 'stanford', download: 'stanford')
      end
    end

    context 'when the object has citation-only access' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'citation-only', download: 'none' })
      end

      it 'maps citation-only view access to dark' do
        call

        expect(content.content_files.sole).to have_attributes(view: 'dark', download: 'none')
      end
    end
  end
end
