# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MimeTypeSupport do
  describe '.for' do
    subject(:mime_type) { described_class.for(path: file_fixture(fixture).to_s, filepath:) }

    context 'when the content is recognized' do
      let(:fixture) { 'page_0001.png' }
      let(:filepath) { 'page_0001.txt' }

      it 'uses the content over the extension' do
        expect(mime_type).to eq('image/png')
      end
    end

    context 'when the content is not recognized' do
      let(:fixture) { 'catalog_record_id_and_barcode.csv' }
      let(:filepath) { 'folder1/catalog_record_id_and_barcode.csv' }

      it 'falls back to the extension of the filepath' do
        expect(mime_type).to eq('text/csv')
      end
    end

    context 'when neither the content nor the extension is recognized' do
      let(:fixture) { 'dropzone_upload.txt' }
      let(:filepath) { 'dropzone_upload' }

      it 'returns the binary type' do
        expect(mime_type).to eq('application/octet-stream')
      end
    end
  end
end
