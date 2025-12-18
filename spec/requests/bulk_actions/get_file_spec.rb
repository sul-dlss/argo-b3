# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Getting bulk action file' do
  let(:user) { create(:user) }
  let!(:bulk_action) { create(:bulk_action, :with_log, user:) }

  context 'when authorized' do
    before do
      sign_in user
    end

    it 'allows downloading the log file' do
      get file_bulk_action_path(bulk_action, filename: 'log.txt')

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('Log content')
      expect(response.header['Content-Disposition']).to include('attachment; filename="log.txt"')
    end
  end

  context 'when not authorized' do
    before do
      sign_in create(:user)
    end

    it 'prevents downloading the log file' do
      get file_bulk_action_path(bulk_action, filename: 'log.txt')

      expect(response).to be_unauthorized
    end
  end
end
