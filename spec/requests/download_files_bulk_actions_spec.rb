# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download files bulk actions' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:user) { create(:user) }

  before do
    sign_in(user)
    allow(BulkActions::DownloadFilesJob).to receive(:perform_later)
  end

  describe 'POST /objects/:object_druid/download_files_bulk_action' do
    it 'creates the bulk action and shows a toast' do
      post "/objects/#{token}/download_files_bulk_action", as: :turbo_stream

      bulk_action = BulkAction.last
      expect(bulk_action).to have_attributes(action_type: 'DOWNLOAD_FILES', description: "Files for #{druid}",
                                             user:, status: 'queued')
      expect(BulkActions::DownloadFilesJob).to have_received(:perform_later).with(bulk_action:, druids: [druid])
      expect(response.body).to include('Download files bulk action created')
      expect(response.body).to include('href="/bulk_actions"')
    ensure
      bulk_action&.remove_output_directory!
    end

    it 'rejects an invalid token' do
      post '/objects/not-a-valid-token/download_files_bulk_action', as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
      expect(BulkAction.count).to eq(0)
    end
  end
end
