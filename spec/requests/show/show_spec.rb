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
end
