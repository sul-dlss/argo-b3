# frozen_string_literal: true

require 'rails_helper'

# The multi-select filter is shared by the Events tab and the Bulk Action and Multi-Item Deposit history filters;
# the Bulk Action history's Statuses filter is used here since it needs no stubbing.
RSpec.describe 'Multi-select filter accessibility' do
  let(:user) { create(:user, :admin) }
  let(:input_selector) { '#bulk_actions_filter_statuses-ts-control' }

  before do
    sign_in(user)
  end

  it 'announces the number selected and the selection of each option' do
    visit bulk_actions_path

    expect(page).to have_css('#bulk_actions_filter_statuses-count[aria-live="polite"]', text: '4 of 4 selected')
    expect(accessibility_node(input_selector)).to include(role: 'combobox', description: '4 of 4 selected')

    find(input_selector).click
    expect(page).to have_css('#bulk_actions_filter_statuses-ts-dropdown .option', count: 4)
    expect(accessibility_node('#bulk_actions_filter_statuses-ts-dropdown'))
      .to include(properties: include(multiselectable: true))

    # The highlighted option is announced with its selection, not as selected because it is highlighted.
    find(input_selector).send_keys('Process', :enter)
    expect(page).to have_css('#bulk_actions_filter_statuses-count', text: '3 of 4 selected')
    expect(accessibility_node('#bulk_actions_filter_statuses-ts-dropdown .option.active'))
      .to include(role: 'option', name: 'Processing', properties: include(selected: false))

    find(input_selector).send_keys(:enter)
    expect(page).to have_css('#bulk_actions_filter_statuses-count', text: '4 of 4 selected')
    expect(accessibility_node('#bulk_actions_filter_statuses-ts-dropdown .option.active'))
      .to include(role: 'option', name: 'Processing', properties: include(selected: true))
  end

  it 'reaches Select all and Select none by keyboard, each named for its field' do
    visit bulk_actions_path

    find_by_id('bulk_actions_filter_action_types-ts-control').click
    find_by_id('bulk_actions_filter_action_types-ts-control').send_keys(:tab)
    expect(page).to have_no_css('#bulk_actions_filter_action_types-ts-dropdown')
    expect(page).to have_css('button[aria-label="Select all actions"]:focus')

    page.send_keys(:tab, :enter)
    expect(page).to have_css('#bulk_actions_filter_action_types-count', text: '0 of 35 selected')
    expect(page).to have_css('button[aria-label="Select all users"]', text: 'Select all')
  end
end
