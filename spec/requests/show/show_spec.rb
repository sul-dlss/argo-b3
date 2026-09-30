# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object' do
  let(:druid) { 'druid:bc123df4567' }

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid' do
    context 'when the object is not found' do
      before do
        allow(Sdr::Repository).to receive(:lock).with(druid:).and_return('v1')
        allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'renders a 404' do
        get "/objects/#{druid}"

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when given a bare druid' do
      let(:druid) { 'bc123df4567' }

      before do
        allow(Sdr::Repository).to receive(:lock).and_return('v1')
        allow(Sdr::Repository).to receive(:find_solr).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'prepends the druid: prefix before looking up the object' do
        get "/objects/#{druid}"

        expect(Sdr::Repository).to have_received(:lock).with(druid: 'druid:bc123df4567')
      end
    end

    context 'when the druid is malformed' do
      it 'renders a 404 without looking up the object' do
        get '/objects/druid%5B%5D=x'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /objects/:druid/track' do
    it 'redirects to the clean object show page' do
      get "/objects/#{druid}/track", params: { search_position: 3 }

      expect(response).to redirect_to("/objects/#{druid}")
      expect(response).to have_http_status(:see_other)
    end

    it 'records the search_position in the last_search cookie' do
      get "/objects/#{druid}/track", params: { search_position: 3 }

      expect(response.cookies['last_search']).to be_present
    end

    context 'without a search_position param' do
      it 'redirects without setting a cookie' do
        get "/objects/#{druid}/track"

        expect(response).to redirect_to("/objects/#{druid}")
        expect(response.cookies['last_search']).to be_nil
      end
    end

    context 'when the request is a Turbo prefetch' do
      it 'redirects without recording the search_position' do
        get "/objects/#{druid}/track", params: { search_position: 3 }, headers: { 'X-Sec-Purpose' => 'prefetch' }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(response.cookies['last_search']).to be_nil
      end
    end

    context 'when the druid is malformed' do
      it 'renders a 404 without redirecting' do
        get '/objects/druid%5B%5D=x/track'

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
