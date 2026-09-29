# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFileSetForm do
  subject(:form) { described_class.from_model(content_file_set) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_file_set) { create(:content_file_set, content:, label: 'Original label', file_set_type: 'file') }
  let!(:content_file) do
    create(:content_file, content_file_set:, position: 1, use: 'transcription',
                          content_file_binary: create(:content_file_binary, content:, mime_type: 'image/tiff'))
  end
  let!(:other_content_file) do
    create(:content_file, content_file_set:, position: 2,
                          content_file_binary: create(:content_file_binary, content:, filepath: 'image2.tif',
                                                                            mime_type: 'image/tiff'))
  end

  describe '#save' do
    it 'updates the file set and its files' do
      form.assign_attributes(label: 'New label', file_set_type: 'image',
                             content_files_attributes: [{ id: content_file.id, use: 'caption',
                                                          mime_type: ' image/jp2 ' }])

      expect(form.save).to be true
      expect(content_file_set.reload).to have_attributes(label: 'New label', file_set_type: 'image')
      expect(content_file.reload.use).to eq('caption')
      expect(content_file.content_file_binary.mime_type).to eq('image/jp2')
    end

    it 'normalizes a blank use to nil' do
      form.assign_attributes(content_files_attributes: [{ id: content_file.id, use: ' ' }])

      form.save

      expect(content_file.reload.use).to be_nil
    end

    context 'when a file is deleted' do
      before do
        # A file being deleted does not need a mime type.
        form.assign_attributes(content_files_attributes: [{ id: content_file.id, mime_type: '', _destroy: 'true' }])
      end

      it 'deletes the file and its unreferenced binary' do
        expect(form.save).to be true

        expect(ContentFile.exists?(content_file.id)).to be false
        expect(ContentFileBinary.exists?(content_file.content_file_binary_id)).to be false
        expect(form.content_file_binaries_destroyed?).to be true
        expect(form.content_file_set_destroyed?).to be false
        expect(ContentFile.exists?(other_content_file.id)).to be true
      end
    end

    context 'when a deleted file shares its binary with another file' do
      let(:other_content_file_set) { create(:content_file_set, content:, position: 2) }

      before do
        create(:content_file, content_file_set: other_content_file_set,
                              content_file_binary: content_file.content_file_binary)
        form.assign_attributes(content_files_attributes: [{ id: content_file.id, _destroy: 'true' }])
      end

      it 'keeps the binary' do
        form.save

        expect(ContentFile.exists?(content_file.id)).to be false
        expect(ContentFileBinary.exists?(content_file.content_file_binary_id)).to be true
        expect(form.content_file_binaries_destroyed?).to be false
      end
    end

    context 'when every file is deleted' do
      before do
        form.assign_attributes(content_files_attributes: [{ id: content_file.id, _destroy: 'true' },
                                                          { id: other_content_file.id, _destroy: 'true' }])
      end

      it 'deletes the file set' do
        expect(form.save).to be true

        expect(ContentFileSet.exists?(content_file_set.id)).to be false
        expect(form.content_file_set_destroyed?).to be true
      end
    end

    context 'when the file set has no files' do
      let(:content_file_set) { create(:content_file_set, content:, label: 'Original label') }
      let!(:content_file) { nil }
      let!(:other_content_file) { nil }

      it 'does not delete the file set' do
        form.assign_attributes(label: 'New label')

        expect(form.save).to be true
        expect(content_file_set.reload.label).to eq('New label')
      end
    end

    context 'when a deleted file has been staged' do
      let(:staging_filepath) do
        StagingSupport.staging_filepath(druid: content.druid, filepath: content_file.content_file_binary.filepath)
      end

      before do
        content_file.content_file_binary.update!(file_location: 'stage')
        FileUtils.mkdir_p(File.dirname(staging_filepath))
        FileUtils.touch(staging_filepath)
        form.assign_attributes(content_files_attributes: [{ id: content_file.id, _destroy: 'true' }])
      end

      after do
        FileUtils.rm_f(staging_filepath)
      end

      it 'deletes the staged file' do
        form.save

        expect(File.exist?(staging_filepath)).to be false
      end
    end

    context 'when a file does not belong to the file set' do
      let(:unrelated_content_file) { create(:content_file) }

      before do
        form.assign_attributes(content_files_attributes: [{ id: unrelated_content_file.id, _destroy: 'true' }])
      end

      it 'raises and does not delete the file' do
        expect { form.save }.to raise_error(ActiveRecord::RecordNotFound)

        expect(ContentFile.exists?(unrelated_content_file.id)).to be true
      end
    end

    context 'when a mime type is blank' do
      before do
        form.assign_attributes(label: 'New label', content_files_attributes: [{ id: content_file.id, mime_type: ' ' }])
      end

      it 'is invalid and does not save' do
        expect(form.save).to be false

        expect(form.errors.attribute_names).to include(:'content_files[0].mime_type')
        expect(content_file_set.reload.label).to eq('Original label')
        expect(content_file.content_file_binary.reload.mime_type).to eq('image/tiff')
      end
    end
  end

  describe '#destroy' do
    it 'deletes the file set, its files, and their unreferenced binaries' do
      form.destroy

      expect(ContentFileSet.exists?(content_file_set.id)).to be false
      expect(ContentFile.where(id: [content_file.id, other_content_file.id])).to be_empty
      expect(ContentFileBinary.where(id: [content_file.content_file_binary_id,
                                          other_content_file.content_file_binary_id])).to be_empty
      expect(form.content_file_binaries_destroyed?).to be true
    end

    context 'when a file shares its binary with another file set' do
      let(:other_content_file_set) { create(:content_file_set, content:, position: 2) }

      before do
        create(:content_file, content_file_set: other_content_file_set,
                              content_file_binary: content_file.content_file_binary)
      end

      it 'keeps the shared binary' do
        form.destroy

        expect(ContentFileBinary.exists?(content_file.content_file_binary_id)).to be true
        expect(ContentFileBinary.exists?(other_content_file.content_file_binary_id)).to be false
      end
    end

    context 'when the file set has no files' do
      let(:content_file_set) { create(:content_file_set, content:) }
      let!(:content_file) { nil }
      let!(:other_content_file) { nil }

      it 'deletes the file set' do
        form.destroy

        expect(ContentFileSet.exists?(content_file_set.id)).to be false
        expect(form.content_file_binaries_destroyed?).to be false
      end
    end

    context 'when a file has been staged' do
      let(:staging_filepath) do
        StagingSupport.staging_filepath(druid: content.druid, filepath: content_file.content_file_binary.filepath)
      end

      before do
        content_file.content_file_binary.update!(file_location: 'stage')
        FileUtils.mkdir_p(File.dirname(staging_filepath))
        FileUtils.touch(staging_filepath)
      end

      after do
        FileUtils.rm_f(staging_filepath)
      end

      it 'deletes the staged file' do
        form.destroy

        expect(File.exist?(staging_filepath)).to be false
      end
    end
  end
end
