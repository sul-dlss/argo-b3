# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a bulk action' do
  let(:user) { create(:user) }
  let!(:bulk_action) { create(:bulk_action, user:, status: :completed) }
  let(:turbo_stream_headers) { { 'Accept' => 'text/vnd.turbo-stream.html, text/html' } }

  before do
    sign_in(user)
  end

  it 'destroys the bulk action and shows a toast' do
    expect do
      delete bulk_action_path(bulk_action), headers: { 'HTTP_REFERER' => bulk_actions_path }
    end.to change(BulkAction, :count).by(-1)

    expect(response).to redirect_to(bulk_actions_path)
    expect(response).to have_http_status(:see_other)
    expect(flash[:toast]).to eq('Bulk action successfully deleted.')
  end

  context 'when the bulk action is incomplete' do
    let!(:bulk_action) { create(:bulk_action, user:) }

    it 'does not destroy the bulk action' do
      expect do
        delete bulk_action_path(bulk_action)
      end.not_to change(BulkAction, :count)

      expect(response).to have_http_status(:conflict)
      expect(flash[:toast]).to be_nil
    end
  end
end
