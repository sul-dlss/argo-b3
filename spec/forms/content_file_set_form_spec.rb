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

    context 'when a file does not belong to the file set' do
      let(:unrelated_content_file) { create(:content_file) }

      before do
        form.assign_attributes(content_files_attributes: [{ id: unrelated_content_file.id, use: 'caption',
                                                            mime_type: 'image/jp2' }])
      end

      it 'raises and does not update the file' do
        expect { form.save }.to raise_error(ActiveRecord::RecordNotFound)

        expect(unrelated_content_file.reload.use).not_to eq('caption')
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
end
