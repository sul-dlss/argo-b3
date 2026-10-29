# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new validate descriptive metadata bulk action' do
  let!(:user) { create(:user) }

  let(:bulk_action_label) { BulkActions::VALIDATE_DESCRIPTIVE_METADATA.label }

  before do
    sign_in user
  end

  context 'when a valid CSV file is provided' do
    it 'submits a validate descriptive metadata bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)
      expect(page).to have_field('Upload a CSV or Excel file', type: 'file')
      expect(page).to have_text('The spreadsheet must include a druid column followed by descriptive metadata ' \
                                'columns conforming to the Cocina schema.')
      expect(page).to have_no_field('Deposit objects once action is complete')

      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/descriptive-upload.csv'

      fill_in 'Describe this bulk action', with: 'Validate descriptive metadata test items'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq('VALIDATE_DESCRIPTIVE_METADATA')
      expect(bulk_action.description).to eq('Validate descriptive metadata test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ValidateDescriptiveMetadataJob)
        .to have_been_enqueued.with(bulk_action:, csv_file: an_instance_of(String))
    end
  end

  context 'with an invalid file' do
    it 'shows an error message' do
      visit new_bulk_actions_validate_descriptive_metadata_path

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/invalid_bulk_upload_descriptive.csv'

      fill_in 'Describe this bulk action', with: 'Validate descriptive metadata test items'

      click_button 'Submit'

      expect(page).to have_invalid_feedback('Upload a CSV or Excel file', text: 'Missing title structured value')
    end
  end
end
