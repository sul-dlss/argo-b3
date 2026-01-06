# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new register bulk action' do
  let!(:user) { create(:user) }

  let(:bulk_action_label) { BulkActions::REGISTER.label }

  before do
    sign_in user
  end

  context 'when a valid CSV file is provided' do
    it 'submits a register bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/bulk_register.csv'

      fill_in 'Describe this bulk action', with: 'Register test items'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::REGISTER.action_type.to_s)
      expect(bulk_action.description).to eq('Register test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::RegisterJob)
        .to have_been_enqueued.with(bulk_action:,
                                    csv_file: an_instance_of(String))
    end
  end

  context 'with an invalid file' do
    it 'shows an error message' do
      visit new_bulk_actions_register_path

      expect(page).to have_css('h1', text: bulk_action_label)
      attach_file 'Upload a CSV or Excel file', 'spec/fixtures/files/bulk_register_bad.csv'

      fill_in 'Describe this bulk action', with: 'Register test items'

      click_button 'Submit'

      expect(page).to have_invalid_feedback('Upload a CSV or Excel file',
                                            text: 'missing headers: administrative_policy_object.')
    end
  end
end
