# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new import catalog data bulk action' do
  let!(:user) { create(:user) }

  let(:bulk_action_label) { BulkActions::IMPORT_CATALOG_DATA.label }

  before do
    sign_in user
  end

  context 'when a valid CSV file is provided' do
    it 'submits an import catalog data bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/import_catalog_data.csv'

      fill_in 'Describe this bulk action', with: 'Import catalog data for test items'

      expect(page).to have_checked_field('Close version once action is complete')
      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::IMPORT_CATALOG_DATA.action_type.to_s)
      expect(bulk_action.description).to eq('Import catalog data for test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ImportCatalogDataJob)
        .to have_been_enqueued.with(bulk_action:,
                                    csv_file: an_instance_of(String),
                                    close_version: true)
    end
  end

  context 'with an invalid file (missing druid column)' do
    it 'shows an error message' do
      visit new_bulk_actions_import_catalog_data_path

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/invalid_import_catalog_data.csv'

      fill_in 'Describe this bulk action', with: 'Import catalog data for test items'

      click_button 'Submit'

      expect(page).to have_invalid_feedback('Upload a CSV or Excel file',
                                            text: 'missing headers: druid.')
    end
  end
end
