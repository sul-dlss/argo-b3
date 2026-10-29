# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show bulk actions history' do
  include ActionView::RecordIdentifier
  include ApplicationHelper

  # This bulk action is owned by a different user, so should not appear in the list.
  let!(:bulk_action_other_user) { create(:bulk_action) }
  let(:user) { create(:user) }

  before do
    FileUtils.rm_rf(Settings.bulk_actions.directory)

    sign_in(user)
  end

  it 'shows the bulk actions for the current user' do
    visit bulk_actions_path

    expect(page).to have_css('h1', text: 'Bulk actions')

    expect(page).to have_table('bulk-actions-history-table')
    expect(page).to have_no_css('table#bulk-actions-history-table tbody tr')
    expect(page).to have_css('p', text: 'No bulk actions.')

    bulk_action = create(:bulk_action, :with_log, :with_export, user:, description: 'First bulk action',
                                                                action_type: 'export_cocina_json')

    row = page.find("tr##{dom_id(bulk_action, 'row')}")
    expect(row).to have_css("td:nth-of-type(1) a[href='#{bulk_action_path(bulk_action)}']",
                            text: "Bulk action #{bulk_action.id}: First bulk action")
    expect(row).to have_css('td:nth-of-type(3)', text: format_datetime(bulk_action.created_at))
    expect(row).to have_css('td:nth-of-type(4)', text: 'Processing')
    expect(row).to have_css('td:nth-of-type(5)', text: '0 / 0 / 0')
    expect(page).to have_css("tr##{dom_id(bulk_action, 'row')}", text: 'First bulk action')
    expect(page).to have_no_css('p', text: 'No bulk actions.')
    expect(page).to have_no_css("tr##{dom_id(bulk_action_other_user, 'row')}")

    bulk_action.update!(druid_count_success: 1, druid_count_fail: 2, druid_count_total: 3)

    expect(row).to have_css('td:nth-of-type(5)', text: '3 / 1 / 2')

    expect(row).to have_css('td:nth-of-type(6) ul > li', count: 2)
    expect(row).to have_css('td:nth-of-type(6) a', text: 'Log file')
    log_txt = with_download('log.txt') do
      row.click_link('Log file')
    end
    expect(log_txt).to eq('Log content')

    expect(row).to have_css('td:nth-of-type(6) a', text: 'Cocina JSON')
    export_txt = with_download('cocina.jsonl.gz') do
      row.click_link('Cocina JSON')
    end
    expect(export_txt).to eq('Export content')
    expect(BulkAction.exists?(bulk_action.id)).to be true
  end

  it 'links to the show page for a bulk action' do
    bulk_action = create(:bulk_action, user:, description: 'First bulk action',
                                       action_type: 'export_cocina_json')

    visit bulk_actions_path

    row = page.find("tr##{dom_id(bulk_action, 'row')}")
    row.click_link("Bulk action #{bulk_action.id}: First bulk action")

    expect(page).to have_current_path(bulk_action_path(bulk_action))
    expect(page).to have_css('h1', text: "Bulk action #{bulk_action.id}: First bulk action")
  end

  it 'filters the bulk actions by action type' do
    redeposit_bulk_action = create(:bulk_action, user:, action_type: 'REDEPOSIT')
    reindex_bulk_action = create(:bulk_action, user:, action_type: 'REINDEX')

    visit bulk_actions_path

    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '33 selected')
    find('#bulk_actions_filter_action_types + .ts-wrapper .ts-control').click
    click_button 'Select none'
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '0 selected')
    click_button 'Select all'
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '33 selected')
    click_button 'Select none'
    find('.ts-dropdown .option', text: 'Redeposit').click
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '1 selected')
    click_button 'Filter'

    expect(page).to have_css("tr##{dom_id(redeposit_bulk_action, 'row')}")
    expect(page).to have_no_css("tr##{dom_id(reindex_bulk_action, 'row')}")
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '1 selected')

    # The select (and the filter) are retained when the page reloads.
    other_redeposit_bulk_action = create(:bulk_action, user:, action_type: 'REDEPOSIT')
    expect(page).to have_css("tr##{dom_id(other_redeposit_bulk_action, 'row')}")
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '1 selected')
    expect(page).to have_no_css('#bulk-actions-filter select[multiple]:not(.tomselected)', visible: :all)
  end

  it 'keeps an open filter and an unsubmitted selection when the page reloads' do
    visit bulk_actions_path

    find('#bulk_actions_filter_action_types + .ts-wrapper .ts-control').click
    click_button 'Select none'
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '0 selected')

    bulk_action = create(:bulk_action, user:, action_type: 'REDEPOSIT')
    expect(page).to have_css("tr##{dom_id(bulk_action, 'row')}")
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-dropdown')
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '0 selected')

    # Closes the dropdown, leaving the selection unsubmitted.
    find('h1').click
    expect(page).to have_no_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-dropdown')

    other_bulk_action = create(:bulk_action, user:, action_type: 'REINDEX')
    expect(page).to have_css("tr##{dom_id(other_bulk_action, 'row')}")
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '0 selected')
  end

  context 'when an admin' do
    let!(:bulk_action_other_user) { create(:bulk_action, user: create(:user, email_address: 'mmouse@stanford.edu')) }
    let(:user) { create(:user, :admin) }

    it 'filters the bulk actions by user' do
      user_bulk_action = create(:bulk_action, user:)

      visit bulk_actions_path

      expect(page).to have_css("tr##{dom_id(user_bulk_action, 'row')}")
      expect(page).to have_no_css("tr##{dom_id(bulk_action_other_user, 'row')}")
      expect(page).to have_css('#bulk_actions_filter_user_ids + .ts-wrapper .ts-count', text: '1 selected')

      find('#bulk_actions_filter_user_ids + .ts-wrapper .ts-control').click
      click_button 'Select all'
      expect(page).to have_css('#bulk_actions_filter_user_ids + .ts-wrapper .ts-count', text: '2 selected')
      click_button 'Filter'

      row = page.find("tr##{dom_id(bulk_action_other_user, 'row')}")
      expect(row).to have_css('td:nth-of-type(2)', text: 'mmouse')
      expect(page).to have_css("tr##{dom_id(user_bulk_action, 'row')}")
    end
  end

  it 'resets the filter when navigating to the unfiltered bulk actions' do
    redeposit_bulk_action = create(:bulk_action, user:, action_type: 'REDEPOSIT')
    reindex_bulk_action = create(:bulk_action, user:, action_type: 'REINDEX')

    visit bulk_actions_path

    find('#bulk_actions_filter_action_types + .ts-wrapper .ts-control').click
    click_button 'Select none'
    find('.ts-dropdown .option', text: 'Redeposit').click
    click_button 'Filter'
    expect(page).to have_no_css("tr##{dom_id(reindex_bulk_action, 'row')}")

    click_button 'Bulk actions'
    click_link 'Recent bulk actions'

    expect(page).to have_css("tr##{dom_id(redeposit_bulk_action, 'row')}")
    expect(page).to have_css("tr##{dom_id(reindex_bulk_action, 'row')}")
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '33 selected')

    page.go_back

    expect(page).to have_no_css("tr##{dom_id(reindex_bulk_action, 'row')}")
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper .ts-count', text: '1 selected')
    expect(page).to have_css('#bulk_actions_filter_action_types + .ts-wrapper', count: 1)
  end

  it 'filters the bulk actions by status' do
    processing_bulk_action = create(:bulk_action, user:)
    completed_bulk_action = create(:bulk_action, user:, status: :completed)

    visit bulk_actions_path

    expect(page).to have_css('#bulk_actions_filter_statuses + .ts-wrapper .ts-count', text: '4 selected')
    find('#bulk_actions_filter_statuses + .ts-wrapper .ts-control').click
    expect(page).to have_no_button('Select all')
    find('.ts-dropdown .option', text: 'Processing').click
    expect(page).to have_css('#bulk_actions_filter_statuses + .ts-wrapper .ts-count', text: '3 selected')
    click_button 'Filter'

    expect(page).to have_css("tr##{dom_id(completed_bulk_action, 'row')}")
    expect(page).to have_no_css("tr##{dom_id(processing_bulk_action, 'row')}")
  end

  it 'filters the bulk actions by submitted date' do
    recent_bulk_action = create(:bulk_action, user:, created_at: 3.days.ago)
    older_bulk_action = create(:bulk_action, user:, created_at: 10.days.ago)

    visit bulk_actions_path

    expect(page).to have_select('Submitted date', selected: 'View all')
    expect(page).to have_css("tr##{dom_id(older_bulk_action, 'row')}")
    select 'Last 7 days', from: 'Submitted date'
    click_button 'Filter'

    expect(page).to have_css("tr##{dom_id(recent_bulk_action, 'row')}")
    expect(page).to have_no_css("tr##{dom_id(older_bulk_action, 'row')}")
    expect(page).to have_select('Submitted date', selected: 'Last 7 days')
  end

  it 'returns to the first page when the filter is submitted' do
    create_list(:bulk_action, BulkActionsController::PER_PAGE + 1, user:, action_type: 'REDEPOSIT')

    visit bulk_actions_path(page: 2)
    expect(page).to have_css('.page-item.active', text: '2')

    click_button 'Filter'

    expect(page).to have_css('.page-item.active', text: '1')
    expect(page).to have_no_current_path(/page=/)
  end
end
