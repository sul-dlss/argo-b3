# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show purl preview' do
  let(:druid) { 'druid:bc123cd4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:cocina_hash) do
    {
      externalIdentifier: druid,
      lock: 'v1'
    }
  end
  let(:cocina_object) { instance_double(Cocina::Models::DRO, to_h: cocina_hash) }
  let(:error) { PurlPreviewService::Error.new('preview failure') }

  before do
    sign_in(create(:user))
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(PurlPreviewService).to receive(:call).with(cocina_hash:).and_raise(error)
    allow(Honeybadger).to receive(:notify)
  end

  describe 'GET /objects/:druid/purl_preview' do
    it 'renders the fallback message and notifies Honeybadger' do
      get "/objects/#{token}/purl_preview"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('PURL preview is not available.')
      expect(PurlPreviewService).to have_received(:call).with(cocina_hash:)
      expect(Honeybadger).to have_received(:notify).with(error, context: { cocina_hash: })
    end
  end
end
