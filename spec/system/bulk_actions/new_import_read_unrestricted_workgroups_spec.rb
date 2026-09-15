# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new import read unrestricted workgroups bulk action' do
  let!(:user) { create(:user, :admin) }

  let(:bulk_action_label) { BulkActions::IMPORT_READ_UNRESTRICTED_WORKGROUPS.label }

  before do
    sign_in user
  end

  context 'when a valid CSV file is provided' do
    it 'submits an import read unrestricted workgroups bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/import_read_unrestricted_workgroups.csv'

      fill_in 'Describe this bulk action', with: 'Update read unrestricted workgroups'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::IMPORT_READ_UNRESTRICTED_WORKGROUPS.action_type.to_s)
      expect(bulk_action.description).to eq('Update read unrestricted workgroups')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ImportReadUnrestrictedWorkgroupsJob)
        .to have_been_enqueued.with(bulk_action:, csv_file: an_instance_of(String))
    end
  end

  context 'with an invalid file' do
    it 'shows an error message' do
      visit new_bulk_actions_import_read_unrestricted_workgroups_path

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file',
                  'spec/fixtures/files/invalid_import_read_unrestricted_workgroups.csv'

      fill_in 'Describe this bulk action', with: 'Update read unrestricted workgroups'

      click_button 'Submit'

      expect(page).to have_invalid_feedback('Upload a CSV or Excel file',
                                            text: 'missing headers: read_unrestricted.')
    end
  end

  context 'when the user is not an admin' do
    let!(:user) { create(:user) }

    it 'does not show the bulk action' do
      visit new_bulk_action_path

      expect(page).to have_css('h1', text: 'New bulk actions')
      expect(page).to have_no_css('#manage-permissions-bulk-actions-section')
      expect(page).to have_no_link(bulk_action_label)
    end
  end
end
