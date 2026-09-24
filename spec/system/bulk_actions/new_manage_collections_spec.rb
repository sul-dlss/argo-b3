# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new update collections bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:collection_druid) { generate(:unique_druid) }
  let(:collection_title) { 'Art History Slides' }

  let(:bulk_action_label) { BulkActions::MANAGE_COLLECTIONS.label }

  before do
    sign_in user

    allow(Searchers::CollectionList).to receive(:call).and_return([[collection_title, collection_druid]])
  end

  it 'submits an update collections bulk action' do
    visit new_bulk_action_path

    click_link bulk_action_label

    expect(page).to have_css('h1', text: bulk_action_label)

    # The fieldset legend and the (visually hidden) select label both read "Collections", so the
    # shared `select_multi_option` helper (which looks up a unique label) can't be used here.
    within('fieldset', text: 'Collections') do
      find('.ts-control input').set(collection_title)
    end
    find('.ts-dropdown .option', text: collection_title, exact_text: true).click

    fill_in 'Enter druid list', with: druids.join("\n")
    fill_in 'Describe this bulk action', with: 'Add test items to a collection'

    expect(page).to have_checked_field('Deposit objects once action is complete')
    click_button 'Submit'

    expect(page).to have_current_path(bulk_actions_path)
    expect(page).to have_toast("#{bulk_action_label} submitted")

    bulk_action = BulkAction.last
    expect(bulk_action.action_type).to eq(BulkActions::MANAGE_COLLECTIONS.action_type.to_s)
    expect(bulk_action.description).to eq('Add test items to a collection')
    expect(bulk_action.user).to eq(user)
    expect(bulk_action.queued?).to be true

    expect(BulkActions::ManageCollectionsJob)
      .to have_been_enqueued.with(bulk_action:, druids:, close_version: true, collection_druids: [collection_druid])
  end

  context 'when no collections are selected' do
    it 'submits a bulk action that will remove the objects from all collections' do
      visit new_bulk_action_path

      click_link bulk_action_label

      fill_in 'Enter druid list', with: druids.join("\n")
      fill_in 'Describe this bulk action', with: 'Remove test items from their collections'

      click_button 'Submit'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      expect(BulkActions::ManageCollectionsJob)
        .to have_been_enqueued.with(bulk_action: BulkAction.last, druids:, close_version: true, collection_druids: [])
    end
  end
end
