# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new manage release bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:bulk_action_label) { BulkActions::MANAGE_RELEASE.label }

  before do
    sign_in user
  end

  # NOTE: Not testing using last search or druids validation since already tested by new_reindex_spec.

  context 'when a list of druids is provided' do
    it 'submits a manage release bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)

      choose 'Do not release this object'

      select 'Search engines', from: 'to'

      fill_in 'Enter druid list', with: druids.join("\n")

      fill_in 'Describe this bulk action', with: 'Manage release test items'
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::MANAGE_RELEASE.action_type.to_s)
      expect(bulk_action.description).to eq('Manage release test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ManageReleaseJob).to have_been_enqueued.with(druids:, bulk_action:, to: 'PURL sitemap',
                                                                       release: false)
    end
  end
end
