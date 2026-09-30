# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new import structural metadata bulk action' do
  let!(:user) { create(:user) }

  let(:bulk_action_label) { BulkActions::IMPORT_STRUCTURAL_METADATA.label }

  before do
    sign_in user
  end

  context 'when a valid CSV file is provided' do
    it 'submits an import structural metadata bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)
      expect(page).to have_text('The spreadsheet must be in the format produced by the ' \
                                '"Export structural metadata" bulk action.')
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/bulk_upload_structural.csv'

      fill_in 'Describe this bulk action', with: 'Import structural metadata for test items'

      expect(page).to have_checked_field('Deposit objects once action is complete')
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::IMPORT_STRUCTURAL_METADATA.action_type.to_s)
      expect(bulk_action.description).to eq('Import structural metadata for test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ImportStructuralMetadataJob)
        .to have_been_enqueued.with(bulk_action:,
                                    csv_file: an_instance_of(String),
                                    close_version: true)
    end
  end

  context 'with an invalid file (missing druid column)' do
    it 'shows an error message' do
      visit new_bulk_actions_import_structural_metadata_path

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/invalid_bulk_upload_structural.csv'

      fill_in 'Describe this bulk action', with: 'Import structural metadata for test items'

      click_button 'Submit'

      expect(page).to have_invalid_feedback('Upload a CSV or Excel file', text: 'missing headers: druid.')
    end
  end
end
