# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing bulk action' do
  let(:user) { create(:user) }
  let!(:bulk_action) { create(:bulk_action, user:, description: 'My bulk action') }

  context 'when authorized' do
    before do
      sign_in user
    end

    it 'shows the bulk action' do
      get bulk_action_path(bulk_action)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('My bulk action')
    end
  end

  context 'when not authorized' do
    before do
      sign_in create(:user)
    end

    it 'prevents showing the bulk action' do
      get bulk_action_path(bulk_action)

      expect(response).to be_unauthorized
    end
  end
end
