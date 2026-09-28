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

    context 'when the file is an export' do
      let!(:bulk_action) { create(:bulk_action, :with_export, action_type: :export_tags, user:) }

      it 'allows downloading the export file' do
        get file_bulk_action_path(bulk_action, filename: 'tags.csv')

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Export content')
      end
    end

    context 'when the file is not a log or export file' do
      it 'returns not found' do
        get file_bulk_action_path(bulk_action, filename: '../../config/database.yml')

        expect(response).to have_http_status(:not_found)
      end
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
