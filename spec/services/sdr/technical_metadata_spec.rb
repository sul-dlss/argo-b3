# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::TechnicalMetadata do
  describe '.find' do
    subject(:technical_metadata) { described_class.find(druid: 'druid:bc123df4567', filepath:) }

    let(:filepath) { 'folder/image 2+a.jp2' }
    let(:url) do
      "#{Settings.tech_md_service.url}/v1/technical-metadata/druid/druid:bc123df4567/file" \
        '?filename=folder%2Fimage+2%2Ba.jp2'
    end
    let(:headers) { { 'Accept' => 'application/json', 'Authorization' => "Bearer #{Settings.tech_md_service.token}" } }

    context 'when service returns OK' do
      let(:body) { { druid: 'druid:bc123df4567', filename: filepath, mimetype: 'image/jp2' }.to_json }

      before do
        stub_request(:get, url).with(headers:).to_return(status: 200, body:)
      end

      it 'returns the technical metadata for the file' do
        expect(technical_metadata).to eq(
          { 'druid' => 'druid:bc123df4567', 'filename' => 'folder/image 2+a.jp2', 'mimetype' => 'image/jp2' }
        )
      end
    end

    context 'when service returns 404' do
      before do
        stub_request(:get, url).with(headers:).to_return(status: 404)
      end

      it 'returns nil' do
        expect(technical_metadata).to be_nil
      end
    end

    context 'when service returns other status' do
      before do
        stub_request(:get, url).with(headers:).to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises' do
        expect { technical_metadata }.to raise_error(
          described_class::Error,
          'Unexpected response (500) from technical-metadata-service for druid:bc123df4567 (folder/image 2+a.jp2): ' \
          'Internal Server Error'
        )
      end
    end
  end
end
