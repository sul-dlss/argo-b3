# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::HistorySectionComponent, type: :component do
  include ActionView::RecordIdentifier

  let(:component) do
    multi_item_deposit_actions = MultiItemDepositAction.where(id: [submitted_multi_item_deposit_action.id,
                                                                   multi_item_deposit_action.id])
    described_class.new(multi_item_deposit_actions: multi_item_deposit_actions.page(1).per(20), filter_form:)
  end

  let(:filter_form) { MultiItemDeposit::FilterForm.new }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, discovery_state: 'discovering',
                                       created_at: Time.zone.parse('2026-04-16T10:00:00Z'))
  end
  let(:submitted_multi_item_deposit_action) do
    create(:multi_item_deposit_action, step: :submitted, description: 'Maps',
                                       initiating_deposit_completed_at: Time.zone.parse('2026-04-17T10:00:00Z'))
  end

  before { create(:item_deposit_action, multi_item_deposit_action: submitted_multi_item_deposit_action) }

  it 'renders the history section with Multi-Item Deposits' do
    render_inline(component)

    expect(page).to have_css('h1', text: 'Multi-item deposits')
    interval = Settings.reload_intervals.multi_item_deposit_actions_history
    expect(page).to have_css("div[data-controller='reload-interval']" \
                             "[data-reload-interval-interval-value='#{interval}']")

    form = page.find("form#multi-item-deposits-filter[action='/multi_item_deposit_actions'][method='get']")
    expect(form).to have_css("select[multiple][data-checkbox-tom-select-select-all-value='true'] " \
                             "option[value='not_submitted'][selected]", text: 'Not submitted')
    expect(form).to have_select('Submitted date', selected: 'View all')
    expect(form).to have_button('Filter', class: 'btn-outline-primary')
    expect(form).to have_no_select('Users')

    table = page.find("table#multi-item-deposits-history-table[aria-label='Multi-item deposits']")
    expect(table).to have_css('thead th:nth-of-type(1)', text: 'Multi-item deposit')
    expect(table).to have_css('thead th:nth-of-type(2)', text: 'Created')
    expect(table).to have_css('thead th:nth-of-type(3)', text: 'Submitted')
    expect(table).to have_css('thead th:nth-of-type(4)', text: 'Status')
    expect(table).to have_css('thead th:nth-of-type(5)', text: 'Workflow status')
    expect(table).to have_css('thead th', count: 5)
    expect(table).to have_css('tbody tr', count: 2)

    row = table.find("tr##{dom_id(multi_item_deposit_action, 'row')}")
    expect(row).to have_css("td:nth-of-type(1) a[href='/multi_item_deposit_actions/#{multi_item_deposit_action.id}']",
                            exact_text: "Multi-item deposit #{multi_item_deposit_action.id}")
    expect(row).to have_css('td:nth-of-type(2)', exact_text: '2026-04-16')
    expect(row).to have_css('td:nth-of-type(3)', exact_text: '')
    expect(row).to have_css('td:nth-of-type(4)', text: 'Discovering files')
    expect(row).to have_no_css('td:nth-of-type(5) a')

    submitted_row = table.find("tr##{dom_id(submitted_multi_item_deposit_action, 'row')}")
    expect(submitted_row).to have_css('td:nth-of-type(1) a',
                                      text: "Multi-item deposit #{submitted_multi_item_deposit_action.id}: Maps")
    expect(submitted_row).to have_css('td:nth-of-type(3)', exact_text: '2026-04-17')
    expect(submitted_row).to have_css('td:nth-of-type(4)', text: 'Submitted')
    expect(submitted_row).to have_link('Workflow status',
                                       href: '/workflow_grid?multi_item_deposit_action_ids%5B%5D=' \
                                             "#{submitted_multi_item_deposit_action.id}")
  end

  context 'when there are no Multi-Item Deposits' do
    let(:component) do
      described_class.new(multi_item_deposit_actions: MultiItemDepositAction.none.page(1).per(20), filter_form:)
    end

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_css('p', text: 'No multi-item deposits yet')
    end
  end

  context 'when there are multiple pages' do
    let(:component) do
      described_class.new(multi_item_deposit_actions: MultiItemDepositAction.all.page(2).per(2), filter_form:)
    end
    let(:filter_form) { MultiItemDeposit::FilterForm.new(statuses: %w[submitted], submitted_date: 'last_7_days') }

    before { create_list(:multi_item_deposit_action, 5) }

    it 'renders pagination controls that retain the filter' do
      render_inline(component)

      expect(page).to have_css("select option[value='submitted'][selected]")
      expect(page).to have_no_css("select option[value='discovering'][selected]")
      expect(page).to have_select('Submitted date', selected: 'Last 7 days')
      expect(page).to have_link('Next »',
                                href: '/multi_item_deposit_actions' \
                                      '?multi_item_deposit_filter%5Bstatuses%5D%5B%5D=submitted' \
                                      '&multi_item_deposit_filter%5Bsubmitted_date%5D=last_7_days&page=3')
    end
  end

  context 'when an admin' do
    let(:filter_form) { MultiItemDeposit::FilterForm.new(user: admin_user, admin: true) }
    let(:admin_user) { create(:user, email_address: 'admin@stanford.edu') }
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, user: create(:user, email_address: 'mmouse@stanford.edu'))
    end

    it 'renders the users filter and the user column' do
      render_inline(component)

      expect(page).to have_css("select[multiple][data-controller='checkbox-tom-select'] " \
                               "option[value='#{admin_user.id}'][selected]", text: 'admin')
      expect(page).to have_css("select option[value='#{multi_item_deposit_action.user_id}']:not([selected])",
                               text: 'mmouse')

      table = page.find('table#multi-item-deposits-history-table')
      expect(table).to have_css('thead th', count: 6)
      expect(table).to have_css('thead th:nth-of-type(2)', text: 'User')

      row = table.find("tr##{dom_id(multi_item_deposit_action, 'row')}")
      expect(row).to have_css('td:nth-of-type(2)', text: 'mmouse')
      expect(row).to have_css('td:nth-of-type(5)', text: 'Not submitted')
    end
  end
end
