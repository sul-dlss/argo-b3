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
  let(:solr_doc) { { Search::Fields::ID => druid } }
  let(:error) { PurlPreviewService::Error.new('preview failure') }

  before do
    sign_in(create(:user))
    allow(Sdr::Repository).to receive(:find).with(druid:, without_structural_contains: true).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:find).with(druid:, without_structural_contains: false).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:find_solr).and_return(solr_doc)
    allow(Honeybadger).to receive(:notify)
  end

  describe 'GET /objects/:druid/purl_preview' do
    context 'when the preview fails' do
      before do
        allow(PurlPreviewService).to receive(:call).and_raise(error)
      end

      it 'renders the fallback message and notifies Honeybadger' do
        get "/objects/#{token}/purl_preview"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('PURL preview is not available.')
        expect(response.body).to include('View PURL page')
        expect(response.body).to include('https://purl.stanford.edu/bc123cd4567')
        expect(PurlPreviewService).to have_received(:call).with(cocina_hash:, constituent_of: [])
        expect(Honeybadger).to have_received(:notify).with(error, context: { cocina_hash: })
      end
    end

    context 'when the object is a constituent of virtual objects' do
      let(:solr_doc) do
        {
          Search::Fields::ID => druid,
          Search::Fields::CONSTITUENT_OF_TITLE_DRUIDS => ['Map set:druid:bb777bb7777',
                                                          'Atlas: volumes:druid:dd666dd6666']
        }
      end

      before do
        allow(PurlPreviewService).to receive(:call).and_return('<html><body><main>Preview</main></body></html>')
      end

      it 'renders the preview with the virtual objects' do
        get "/objects/#{token}/purl_preview"

        expect(response.body).to include('Preview')
        expect(PurlPreviewService).to have_received(:call)
          .with(cocina_hash:, constituent_of: [['druid:bb777bb7777', 'Map set'],
                                               ['druid:dd666dd6666', 'Atlas: volumes']])
      end
    end
  end
end
