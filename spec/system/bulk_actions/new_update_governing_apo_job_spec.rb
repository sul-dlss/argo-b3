# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new update governing APO bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:new_apo_id) { generate(:unique_druid) }
  let(:new_apo_title) { 'New APO' }

  let(:bulk_action_label) { BulkActions::UPDATE_GOVERNING_APO.label }

  before do
    sign_in user

    allow(Searchers::AdminPolicyList).to receive(:call).and_return([[new_apo_title, new_apo_id]])
  end

  context 'when there are more than 50 APOs' do
    before do
      apos = (1..60).map { |n| [format('APO %02d', n), "druid:bc#{format('%03d', n)}df4567"] }
      allow(Searchers::AdminPolicyList).to receive(:call).and_return(apos)
    end

    it 'shows all of the matching APOs' do
      visit new_bulk_action_path
      click_link bulk_action_label

      apo_select = search_searchable_select('APO', from: 'New governing APO')

      expect(apo_select).to have_css('.ts-dropdown .option', count: 60)
      apo_select.find('.ts-dropdown .option', exact_text: 'APO 60').click
      expect(apo_select).to have_css('.ts-control .item', exact_text: 'APO 60')
    end
  end

  it 'submits an update governing APO bulk action' do
    visit new_bulk_action_path

    click_link bulk_action_label

    expect(page).to have_css('h1', text: bulk_action_label)
    expect(Searchers::AdminPolicyList).to have_received(:call).with(user_scope: Permissions::UserScope, editable: true)

    select_searchable_option(new_apo_title, from: 'New governing APO')

    fill_in 'Enter druid list', with: druids.join("\n")
    fill_in 'Describe this bulk action', with: 'Move test items to a new governing APO'

    expect(page).to have_checked_field('Deposit objects once action is complete')
    click_button 'Submit'

    expect(page).to have_current_path(bulk_actions_path)
    expect(page).to have_toast("#{bulk_action_label} submitted")

    bulk_action = BulkAction.last
    expect(bulk_action.action_type).to eq(BulkActions::UPDATE_GOVERNING_APO.action_type.to_s)
    expect(bulk_action.description).to eq('Move test items to a new governing APO')
    expect(bulk_action.user).to eq(user)
    expect(bulk_action.queued?).to be true

    expect(BulkActions::UpdateGoverningApoJob)
      .to have_been_enqueued.with(bulk_action:, druids:, close_version: true, new_apo_id:)
  end
end
