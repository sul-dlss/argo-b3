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

    # bulk_action_path is checked as a quoted href value rather than a bare substring, since a bare
    # numeric id (e.g. "/bulk_actions/1") can otherwise be a substring of another rendered row's path
    # (e.g. "/bulk_actions/19"), causing spurious matches depending on the ids assigned by the database.
    it 'paginates the first page' do
      get bulk_actions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{bulk_action_path(bulk_actions.last)}"))
      expect(response.body).not_to include(%(href="#{bulk_action_path(bulk_actions.first)}"))
    end

    it 'paginates the second page' do
      get bulk_actions_path(page: 2)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{bulk_action_path(bulk_actions.first)}"))
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

  context 'when filtering by action type' do
    let!(:redeposit_bulk_action) { create(:bulk_action, action_type: 'REDEPOSIT', user:) }
    let!(:reindex_bulk_action) { create(:bulk_action, action_type: 'REINDEX', user:) }
    let!(:republish_bulk_action) { create(:bulk_action, action_type: 'REPUBLISH', user:) }

    it 'lists only the bulk actions of the selected action types' do
      get bulk_actions_path(bulk_actions_filter: { action_types: %w[REDEPOSIT REINDEX] })

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{bulk_action_path(redeposit_bulk_action)}"))
      expect(response.body).to include(%(href="#{bulk_action_path(reindex_bulk_action)}"))
      expect(response.body).not_to include(%(href="#{bulk_action_path(republish_bulk_action)}"))
    end

    it 'lists no bulk actions when no action types are selected' do
      get bulk_actions_path(bulk_actions_filter: { action_types: [''] })

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('No bulk actions.')
    end
  end

  context 'when filtering by status' do
    let!(:processing_bulk_action) { create(:bulk_action, user:) }
    let!(:completed_bulk_action) { create(:bulk_action, status: :completed, user:) }

    it 'lists only the bulk actions with the selected statuses' do
      get bulk_actions_path(bulk_actions_filter: { statuses: ['', 'completed'] })

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{bulk_action_path(completed_bulk_action)}"))
      expect(response.body).not_to include(%(href="#{bulk_action_path(processing_bulk_action)}"))
    end
  end

  context 'when filtering by submitted date' do
    let!(:recent_bulk_action) { create(:bulk_action, user:, created_at: 2.weeks.ago) }
    let!(:older_bulk_action) { create(:bulk_action, user:, created_at: 2.months.ago) }

    it 'lists only the bulk actions submitted within the range' do
      get bulk_actions_path(bulk_actions_filter: { submitted_date: 'last_month' })

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{bulk_action_path(recent_bulk_action)}"))
      expect(response.body).not_to include(%(href="#{bulk_action_path(older_bulk_action)}"))
    end
  end

  context 'when not filtering by action type' do
    # Its action type matches no filter value, so it is listed only when no filter is applied.
    let!(:legacy_bulk_action) { create(:bulk_action, action_type: 'reindex', user:) }

    it 'lists bulk actions of every action type' do
      get bulk_actions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{bulk_action_path(legacy_bulk_action)}"))
    end
  end
end
