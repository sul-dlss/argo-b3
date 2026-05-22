# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new export tracking sheets bulk action' do
  let!(:user) { create(:user) }

  let(:druids) { ['druid:pj757vx3102', 'druid:rt276nw8963'] }

  let(:bulk_action_label) { BulkActions::EXPORT_TRACKING_SHEETS.label }

  before do
    sign_in user
  end

  context 'when a list of druids is provided' do
    it 'submits an export tracking sheets bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)
      fill_in 'Enter druid list', with: druids.join("\n")

      fill_in 'Describe this bulk action', with: 'Export tracking sheets for test items'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::EXPORT_TRACKING_SHEETS.action_type.to_s)
      expect(bulk_action.description).to eq('Export tracking sheets for test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ExportTrackingSheetsJob).to have_been_enqueued.with(druids:, bulk_action:)
    end
  end
end
