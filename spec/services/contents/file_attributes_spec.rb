# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::FileAttributes do
  subject(:file_attributes) { described_class.call(mime_type:, **options) }

  let(:options) { {} }

  describe 'without OCR' do
    context 'when the mime type is a master image' do
      let(:mime_type) { 'image/tiff' }

      it 'preserves but does not shelve or publish' do
        expect(file_attributes).to eq({ preserve: true, shelve: false, publish: false, use: nil })
      end
    end

    context 'when the mime type is a deliverable image' do
      let(:mime_type) { 'image/jp2' }

      it 'shelves and publishes but does not preserve' do
        expect(file_attributes).to eq({ preserve: false, shelve: true, publish: true, use: nil })
      end
    end

    context 'when the mime type is XML' do
      let(:mime_type) { 'application/xml' }

      it 'falls back to the default attributes' do
        expect(file_attributes).to eq({ preserve: true, shelve: false, publish: false, use: nil })
      end
    end

    context 'when the mime type is not mapped' do
      let(:mime_type) { 'application/octet-stream' }

      it 'falls back to the default attributes' do
        expect(file_attributes).to eq({ preserve: true, shelve: false, publish: false, use: nil })
      end
    end

    context 'when the mime type is nil' do
      let(:mime_type) { nil }

      it 'falls back to the default attributes' do
        expect(file_attributes).to eq({ preserve: true, shelve: false, publish: false, use: nil })
      end
    end
  end

  describe 'with OCR' do
    let(:options) { { ocr: true } }

    context 'when the mime type is a deliverable image' do
      let(:mime_type) { 'image/jp2' }

      it 'also preserves' do
        expect(file_attributes).to eq({ preserve: true, shelve: true, publish: true, use: nil })
      end
    end

    context 'when the mime type is XML' do
      let(:mime_type) { 'application/xml' }

      it 'is a transcription' do
        expect(file_attributes).to eq({ preserve: true, shelve: true, publish: true, use: 'transcription' })
      end
    end

    context 'when the mime type is PDF' do
      let(:mime_type) { 'application/pdf' }

      it 'is a transcription' do
        expect(file_attributes).to eq({ preserve: true, shelve: true, publish: true, use: 'transcription' })
      end
    end

    context 'when the mime type is plain text' do
      let(:mime_type) { 'text/plain' }

      it 'is not a transcription' do
        expect(file_attributes).to eq({ preserve: true, shelve: true, publish: true, use: nil })
      end
    end

    context 'when the mime type is not in the OCR mapping' do
      let(:mime_type) { 'application/zip' }

      it 'falls back to the mapping without OCR' do
        expect(file_attributes).to eq({ preserve: true, shelve: false, publish: false, use: nil })
      end
    end
  end
end
