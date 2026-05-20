# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show Solr document' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:invalid_token) { 'not-a-valid-token' }
  let(:solr_doc) { { 'id' => druid, 'title_tesi' => 'My object' } }

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid/solr_doc' do
    context 'with a valid token' do
      before do
        allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return(solr_doc)
      end

      it 'renders the solr document as JSON' do
        get "/objects/#{token}/solr_doc"

        expect(response).to have_http_status(:ok)
        expect(Sdr::Repository).to have_received(:find_solr).with(druid:)
      end
    end

    context 'with an invalid token' do
      it 'raises when token verification fails' do
        get "/objects/#{invalid_token}/solr_doc"

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
