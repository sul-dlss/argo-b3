# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cancelling a bulk action' do
  let(:user) { create(:user, :admin) }

  before do
    sign_in(user)
  end

  context 'when the bulk action is cancellable' do
    let(:bulk_action) { create(:bulk_action, status: :started) }

    it 'sets the bulk action to cancelling and shows a toast' do
      post cancel_bulk_action_path(bulk_action), headers: { 'HTTP_REFERER' => bulk_actions_path }

      expect(response).to redirect_to(bulk_actions_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Bulk action is being cancelled.')
      expect(bulk_action.reload).to be_cancelling
    end
  end

  context 'when the bulk action is not cancellable' do
    let(:bulk_action) { create(:bulk_action, status: :completed) }

    it 'redirects to the index with an alert' do
      post cancel_bulk_action_path(bulk_action)

      expect(response).to redirect_to(bulk_actions_path)
      expect(flash[:danger]).to eq('Bulk action could not be cancelled.')
      expect(bulk_action.reload).to be_completed
    end
  end

  context 'when not an admin' do
    let(:user) { create(:user) }
    let(:bulk_action) { create(:bulk_action, user:, status: :started) }

    it 'does not cancel the bulk action' do
      post cancel_bulk_action_path(bulk_action)

      expect(response).to redirect_to(root_path)
      expect(flash[:warning]).to eq('You are not authorized to perform the requested action.')
      expect(bulk_action.reload).to be_started
    end
  end
end
