# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::TechnicalMetadata do
  describe '.find' do
    subject(:technical_metadata) { described_class.find(druid: 'druid:bc123df4567', filepath:) }

    let(:filepath) { 'folder/image2.jp2' }
    let(:url) { 'https://techmd-stage.stanford.edu/v1/technical-metadata/druid/druid:bc123df4567' }
    let(:token) { 'mint-token-with-target-techmd-service-rake-generate-token' }
    let(:headers) { { 'Accept' => 'application/json', 'Authorization' => "Bearer #{token}" } }

    context 'when service returns OK' do
      let(:body) do
        [
          { druid: 'druid:bc123df4567', filename: 'image1.jp2', mimetype: 'image/jp2' },
          { druid: 'druid:bc123df4567', filename: 'folder/image2.jp2', mimetype: 'image/jp2' }
        ].to_json
      end

      before do
        stub_request(:get, url).with(headers:).to_return(status: 200, body:)
      end

      it 'returns the technical metadata for the file' do
        expect(technical_metadata).to eq(
          { 'druid' => 'druid:bc123df4567', 'filename' => 'folder/image2.jp2', 'mimetype' => 'image/jp2' }
        )
      end

      context 'when the file is not in the response' do
        let(:filepath) { 'image3.jp2' }

        it 'returns nil' do
          expect(technical_metadata).to be_nil
        end
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
          'Unexpected response (500) from technical-metadata-service for druid:bc123df4567: Internal Server Error'
        )
      end
    end
  end
end
