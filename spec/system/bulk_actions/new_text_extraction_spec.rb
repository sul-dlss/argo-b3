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

      select_multi_option 'English', from: 'Search for a language'

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

  context 'when selecting languages with the keyboard' do
    it 'commits the highlighted language on either Enter or Tab' do
      visit new_bulk_actions_text_extraction_path

      expect(page).to have_css('h1', text: bulk_action_label)

      select_multi_option_with_key 'Danis', from: 'Search for a language', key: :enter
      select_multi_option_with_key 'Engl', from: 'Search for a language', key: :tab

      items = find_multi_select_items(from: 'Search for a language')
      expect(items.map(&:text)).to contain_exactly(a_string_starting_with('Danish'),
                                                   a_string_starting_with('English'))
    end
  end

  context 'when more than the recommended number of languages is selected' do
    let(:languages) do
      %w[Afrikaans Albanian Basque Danish English Finnish Hawaiian Icelandic Zulu]
    end

    it 'warns the user until a language is removed' do
      visit new_bulk_actions_text_extraction_path

      expect(page).to have_css('h1', text: bulk_action_label)
      expect(page).to have_no_text('Selecting more than eight text-extraction languages')

      languages.each { |language| select_multi_option language, from: 'Search for a language' }

      expect(find_multi_select_items(from: 'Search for a language').size).to eq(9)
      expect(page).to have_text('Selecting more than eight text-extraction languages')

      remove_first_multi_option from: 'Search for a language'

      expect(find_multi_select_items(from: 'Search for a language').size).to eq(8)
      expect(page).to have_no_text('Selecting more than eight text-extraction languages')
    end
  end
end
