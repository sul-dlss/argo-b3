# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroying bulk action' do
  let(:user) { create(:user) }
  let!(:bulk_action) { create(:bulk_action, user:) }

  context 'when authorized' do
    before do
      sign_in user
    end

    it 'allows deleting the bulk action' do
      expect do
        delete bulk_action_path(bulk_action)
      end.to change(BulkAction, :count).by(-1)

      expect(response).to redirect_to(bulk_actions_path)
      follow_redirect!

      expect(response.body).to include('Bulk action deleted.')
    end
  end

  context 'when not authorized' do
    before do
      sign_in create(:user)
    end

    it 'prevents deleting the bulk action' do
      delete bulk_action_path(bulk_action)

      expect(response).to be_unauthorized

      expect(BulkAction.exists?(bulk_action.id)).to be true
    end
  end
end
