# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new manage content type bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:bulk_action_label) { BulkActions::MANAGE_CONTENT_TYPE.label }

  before do
    sign_in user
  end

  # NOTE: Not testing using last search or druids validation since already tested by new_reindex_spec.

  context 'when a content type is selected without resource type remapping' do
    it 'submits a manage content type bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)

      select 'image', from: 'New content type'

      fill_in 'Enter druid list', with: druids.join("\n")
      fill_in 'Describe this bulk action', with: 'Update content type for test items'

      expect(page).to have_checked_field('Close version once action is complete')
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::MANAGE_CONTENT_TYPE.action_type.to_s)
      expect(bulk_action.description).to eq('Update content type for test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ManageContentTypeJob).to have_been_enqueued.with(
        druids:,
        bulk_action:,
        close_version: true,
        current_resource_type: nil,
        new_content_type: Cocina::Models::ObjectType.image,
        new_resource_type: nil,
        viewing_direction: nil
      )
    end
  end

  context 'when a content type and resource type remapping are both selected' do
    it 'submits a manage content type bulk action with resource type remapping' do
      visit new_bulk_actions_manage_content_type_path

      check 'Change viewing direction (books and images only)'
      check 'Change resource types'

      select 'book', from: 'New content type'
      select 'left-to-right', from: 'Viewing direction'
      select 'page', from: 'Current resource type'
      select 'page', from: 'New resource type'

      fill_in 'Enter druid list', with: druids.join("\n")
      fill_in 'Describe this bulk action', with: 'Update to book with page resource type'

      uncheck 'Close version once action is complete'
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      expect(BulkActions::ManageContentTypeJob).to have_been_enqueued.with(
        druids:,
        bulk_action: BulkAction.last,
        close_version: false,
        current_resource_type: Cocina::Models::FileSetType.page,
        new_content_type: Cocina::Models::ObjectType.book,
        new_resource_type: Cocina::Models::FileSetType.page,
        viewing_direction: 'left-to-right'
      )
    end
  end
end
