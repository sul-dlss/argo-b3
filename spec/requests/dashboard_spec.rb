# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }

  before do
    sign_in(user)
  end

  it 'renders the dashboard' do
    get root_path

    expect(response).to have_http_status(:ok)
  end

  describe 'POST /go_to_druid' do
    before do
      allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return({})
    end

    it 'redirects to the object when given a prefixed druid' do
      post go_to_druid_path, params: { go_to_druid: { druid: } }

      expect(response).to redirect_to(object_path(druid))
      expect(Sdr::Repository).to have_received(:find_solr).with(druid:)
    end

    it 'redirects to the object when given an unprefixed druid' do
      post go_to_druid_path, params: { go_to_druid: { druid: 'bc123df4567' } }

      expect(response).to redirect_to(object_path(druid))
      expect(Sdr::Repository).to have_received(:find_solr).with(druid:)
    end

    context 'when the druid does not exist' do
      before do
        allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'renders a validation error' do
        post go_to_druid_path, params: { go_to_druid: { druid: } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('does not exist')
      end
    end

    context 'when the druid is invalid' do
      it 'renders a validation error without looking up the object' do
        post go_to_druid_path, params: { go_to_druid: { druid: 'not-a-druid' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('is not a valid druid')
        expect(Sdr::Repository).not_to have_received(:find_solr)
      end
    end
  end
end
