# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new reindex bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  before do
    sign_in user
  end

  context 'when a list of druids is provided' do
    it 'submits a reindex bulk action' do
      visit new_bulk_action_path

      click_link 'Reindex'

      expect(page).to have_css('h1', text: 'Reindex')

      fill_in 'Enter druid list', with: druids.join("\n")

      fill_in 'Describe this bulk action', with: 'Reindex test items'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast('Reindex submitted')

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::REINDEX.action_type.to_s)
      expect(bulk_action.description).to eq('Reindex test items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::ReindexJob).to have_been_enqueued.with(druids:, bulk_action:)
    end
  end

  context 'when using last search' do
    let(:search_form) { SearchForm.new(query: 'test') }

    before do
      set_last_search_cookie(search_form:)
      allow(Searchers::DruidList).to receive(:call).and_return(druids)
    end

    it 'submits a reindex bulk action' do
      visit new_bulk_actions_reindex_path

      expect(page).to have_css('h1', text: 'Reindex')

      choose 'From last search'

      fill_in 'Describe this bulk action', with: 'Reindex last search items'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)

      expect(page).to have_toast('Reindex submitted')

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::REINDEX.action_type.to_s)
      expect(bulk_action.description).to eq('Reindex last search items')
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(Searchers::DruidList).to have_received(:call).with(matching_form(search_form))
      expect(BulkActions::ReindexJob).to have_been_enqueued.with(druids:, bulk_action:)
    end
  end

  context 'when no druids are provided' do
    it 'shows validation errors' do
      visit new_bulk_actions_reindex_path

      expect(page).to have_css('h1', text: 'Reindex')

      click_button 'Submit'

      expect(page).to have_current_path(new_bulk_actions_reindex_path)

      expect(page).to have_invalid_feedback('Enter druid list', 'can\'t be blank')
    end
  end
end
