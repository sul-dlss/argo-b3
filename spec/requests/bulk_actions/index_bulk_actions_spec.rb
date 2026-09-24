# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing bulk actions history' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context 'when there are more bulk actions than fit on one page' do
    let!(:bulk_actions) do
      create_list(:bulk_action, BulkActionsController::PER_PAGE + 1, user:)
    end

    it 'paginates the first page' do
      get bulk_actions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(bulk_action_path(bulk_actions.last))
      expect(response.body).not_to include(bulk_action_path(bulk_actions.first))
    end

    it 'paginates the second page' do
      get bulk_actions_path(page: 2)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(bulk_action_path(bulk_actions.first))
    end
  end

  context 'when there is only one page of bulk actions' do
    before { create(:bulk_action, user:) }

    it 'does not render pagination controls' do
      get bulk_actions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('paginate-section')
    end
  end
end
