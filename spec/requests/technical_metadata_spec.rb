# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Technical metadata' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:technical_metadata) do
    { 'druid' => 'druid:bc123df4567', 'filename' => 'folder1/image1.tif', 'mimetype' => 'image/tiff' }
  end

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:object_druid/technical_metadata' do
    context 'when there is technical metadata for the file' do
      before do
        allow(Sdr::TechnicalMetadata).to receive(:find).and_return(technical_metadata)
      end

      it 'renders the technical metadata in the requesting frame' do
        get "/objects/#{token}/technical_metadata", params: { filepath: 'folder1/image1.tif' },
                                                    headers: { 'Turbo-Frame' => 'techmd-frame' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<turbo-frame id="techmd-frame">')
        expect(response.body).to include('<dt class="col-sm-3 col-lg-2">Mimetype</dt>')
        expect(response.body).to include('image/tiff')
        expect(response.body).not_to include('Druid')
        expect(response.body).not_to include('Filename')
        expect(Sdr::TechnicalMetadata).to have_received(:find).with(druid:, filepath: 'folder1/image1.tif')
      end
    end

    context 'when there is no technical metadata for the file' do
      before do
        allow(Sdr::TechnicalMetadata).to receive(:find).and_return(nil)
      end

      it 'renders a message' do
        get "/objects/#{token}/technical_metadata", params: { filepath: 'folder1/image1.tif' },
                                                    headers: { 'Turbo-Frame' => 'techmd-frame' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('No technical metadata')
      end
    end

    it 'raises when token verification fails' do
      get '/objects/not-a-valid-token/technical_metadata', params: { filepath: 'folder1/image1.tif' }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
