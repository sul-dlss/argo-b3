# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populator do
  subject(:call) { described_class.call(content:, cocina_object:, files:, paths:) }

  let(:content) { instance_double(Content) }
  let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata) }
  let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
  let(:files) { { '0' => uploaded_file } }
  let(:paths) { { '0' => 'folder/dropzone_upload.txt' } }

  before do
    allow(Contents::Populators::FileSetPerFile).to receive(:call)
  end

  describe '.call' do
    it 'delegates to the file set per file populator' do
      call

      expect(Contents::Populators::FileSetPerFile).to have_received(:call)
        .with(content:, cocina_object:, files:, paths:)
    end

    context 'when some filepaths should be ignored' do
      let(:ignored_file) { instance_double(ActionDispatch::Http::UploadedFile) }
      let(:files) { { '0' => uploaded_file, '1' => ignored_file } }
      let(:paths) { { '0' => 'folder/dropzone_upload.txt', '1' => 'folder/._dropzone_upload.txt' } }

      it 'passes along only the files that should not be ignored' do
        call

        expect(Contents::Populators::FileSetPerFile).to have_received(:call)
          .with(content:, cocina_object:, files: { '0' => uploaded_file },
                paths: { '0' => 'folder/dropzone_upload.txt' })
      end
    end

    context 'when all filepaths should be ignored' do
      let(:paths) { { '0' => 'folder/._dropzone_upload.txt' } }

      it 'passes along no files' do
        call

        expect(Contents::Populators::FileSetPerFile).to have_received(:call)
          .with(content:, cocina_object:, files: {}, paths: {})
      end
    end
  end
end
