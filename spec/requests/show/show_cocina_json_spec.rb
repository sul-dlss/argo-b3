# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show cocina json' do
  let(:invalid_token) { 'not-a-valid-token' }

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid/json' do
    before do
      allow(Sdr::Repository).to receive(:find)
    end

    it 'raises when token verification fails' do
      get "/objects/#{invalid_token}/json"

      expect(response).to have_http_status(:forbidden)
      expect(Sdr::Repository).not_to have_received(:find)
    end
  end
end
