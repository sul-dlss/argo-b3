# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show workflows' do
  let(:invalid_token) { 'not-a-valid-token' }

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid/workflows' do
    before do
      allow(Sdr::WorkflowService).to receive(:workflows_for)
    end

    it 'raises when token verification fails' do
      get "/objects/#{invalid_token}/workflows"

      expect(response).to have_http_status(:forbidden)
      expect(Sdr::WorkflowService).not_to have_received(:workflows_for)
    end
  end
end
