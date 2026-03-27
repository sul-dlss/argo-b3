# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new manage source id bulk action' do
  let!(:user) { create(:user) }

  let(:bulk_action_label) { BulkActions::MANAGE_SOURCE_ID.label }

  before do
    sign_in user
  end

  context 'when a valid CSV file is provided' do
    it 'submits a manage source id bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/manage_source_id.csv'

      fill_in 'Describe this bulk action', with: 'Update source ids for test items'

      expect(page).to have_checked_field('Close version once action is complete')
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::MANAGE_SOURCE_ID.action_type.to_s)
      expect(bulk_action.description).to eq('Update source ids for test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ManageSourceIdJob)
        .to have_been_enqueued.with(bulk_action:,
                                    csv_file: an_instance_of(String),
                                    close_version: true)
    end
  end

  context 'with an invalid file' do
    it 'shows an error message' do
      visit new_bulk_actions_manage_source_id_path

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/invalid_manage_source_id.csv'

      fill_in 'Describe this bulk action', with: 'Update source ids for test items'

      click_button 'Submit'

      expect(page).to have_invalid_feedback('Upload a CSV or Excel file',
                                            text: 'missing headers: source_id.')
    end
  end
end
