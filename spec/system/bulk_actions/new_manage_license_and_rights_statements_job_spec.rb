# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new manage license and rights statements bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:bulk_action_label) { BulkActions::MANAGE_LICENSE_AND_RIGHTS_STATEMENTS.label }

  before do
    sign_in user
  end

  # NOTE: Not testing using last search or druids validation since already tested by new_reindex_spec.
  context 'when a list of druids is provided' do
    it 'submits a manage license and rights statements bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)

      fill_in 'Enter druid list', with: druids.join("\n")

      choose 'Update use and reproduction statement'
      fill_in 'Use and reproduction statement', with: 'Please contact rights holder for use.'

      choose 'Update copyright statement'
      fill_in 'Copyright statement', with: 'Copyright Stanford University'

      choose 'Update license'
      select 'CC Attribution 4.0 International', from: 'License'

      fill_in 'Describe this bulk action', with: 'Update license and rights statements for test items'
      expect(page).to have_checked_field('Close version once action is complete')
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::MANAGE_LICENSE_AND_RIGHTS_STATEMENTS.action_type.to_s)
      expect(bulk_action.description).to eq('Update license and rights statements for test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ManageLicenseAndRightsStatementsJob)
        .to have_been_enqueued.with(
          druids:,
          bulk_action:,
          close_version: true,
          change_copyright: true,
          copyright: 'Copyright Stanford University',
          change_license: true,
          license: 'https://creativecommons.org/licenses/by/4.0/legalcode',
          change_use_and_reproduction_statement: true,
          use_and_reproduction_statement: 'Please contact rights holder for use.'
        )
    end
  end

  context 'when do not update is selected for all fields' do
    it 'submits a bulk action with no change flags' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)

      fill_in 'Enter druid list', with: druids.join("\n")
      fill_in 'Describe this bulk action', with: 'No rights updates for test items'

      expect(page).to have_checked_field('Close version once action is complete')
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last

      expect(BulkActions::ManageLicenseAndRightsStatementsJob)
        .to have_been_enqueued.with(
          druids:,
          bulk_action:,
          close_version: true,
          change_copyright: false,
          copyright: nil,
          change_license: false,
          license: nil,
          change_use_and_reproduction_statement: false,
          use_and_reproduction_statement: nil
        )
    end
  end

  context 'when remove is selected for all fields' do
    it 'submits a bulk action with change flags and nil replacement values' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)

      fill_in 'Enter druid list', with: druids.join("\n")

      choose 'Remove existing use and reproduction statement'
      choose 'Remove existing copyright statement'
      choose 'Remove existing license'
      uncheck 'Close version once action is complete'

      fill_in 'Describe this bulk action', with: 'Remove rights statements for test items'
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last

      expect(BulkActions::ManageLicenseAndRightsStatementsJob)
        .to have_been_enqueued.with(
          druids:,
          bulk_action:,
          close_version: false,
          change_copyright: true,
          copyright: nil,
          change_license: true,
          license: nil,
          change_use_and_reproduction_statement: true,
          use_and_reproduction_statement: nil
        )
    end
  end
end
