# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new open version bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:bulk_action_label) { BulkActions::OPEN_VERSION.label }

  before do
    sign_in user
  end

  # NOTE: Not testing using last search or druids validation since already tested by new_reindex_spec.

  context 'when a list of druids is provided' do
    it 'submits a open version bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)

      fill_in 'Enter druid list', with: druids.join("\n")

      fill_in 'Describe this version', with: 'Test version'

      fill_in 'Describe this bulk action', with: 'Open version test items'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::OPEN_VERSION.action_type.to_s)
      expect(bulk_action.description).to eq('Open version test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::OpenVersionJob)
        .to have_been_enqueued.with(druids:, bulk_action:, version_description: 'Test version')
    end
  end
end
