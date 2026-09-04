# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new text extraction bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:bulk_action_label) { BulkActions::TEXT_EXTRACTION.label }

  before do
    sign_in user
  end

  context 'when a list of druids is provided' do
    it 'submits a text extraction bulk action' do
      visit new_bulk_action_path

      click_link bulk_action_label

      expect(page).to have_css('h1', text: bulk_action_label)

      fill_in 'Enter druid list', with: druids.join("\n")

      # The language checkboxes are hidden behind a dropdown until the search input is focused.
      find('input[aria-label="Search avalaible Abbyy languages"]').click
      check 'English'

      fill_in 'Describe this bulk action', with: 'Extract text for test items'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::TEXT_EXTRACTION.action_type.to_s)
      expect(bulk_action.description).to eq('Extract text for test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::TextExtractionJob)
        .to have_been_enqueued.with(druids:, bulk_action:, text_extraction_languages: ['English'])
    end
  end
end
