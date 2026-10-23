# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::HistorySectionComponent, type: :component do
  include ActionView::RecordIdentifier

  let(:component) do
    described_class.new(bulk_actions: BulkAction.where(id: [bulk_action.id, bulk_action_with_files.id])
                                                .page(1).per(20),
                        filter_form:)
  end

  let(:filter_form) { BulkActions::FilterForm.new }
  let(:bulk_action) do
    create(:bulk_action, action_type: :reindex, description: 'Test description',
                         created_at: Time.zone.parse('2026-04-16T10:00:00Z'))
  end
  let(:bulk_action_with_files) do
    create(:bulk_action, :with_log, :with_export,
           action_type: :export_cocina_json,
           status: :completed,
           druid_count_success: 5, druid_count_fail: 2, druid_count_total: 7)
  end

  it 'renders the history section with bulk actions' do
    render_inline(component)

    expect(page).to have_css('h1', text: 'Bulk actions')

    form = page.find("form#bulk-actions-filter[action='/bulk_actions'][method='get']")
    expect(form).to have_css("select[multiple][data-controller='checkbox-tom-select'] " \
                             "option[value='REDEPOSIT'][selected]", text: 'Redeposit')
    expect(form).to have_css("select[multiple][data-checkbox-tom-select-select-all-value='false'] " \
                             "option[value='completed_with_errors'][selected]", text: 'Completed with errors')
    expect(form).to have_select('Submitted date', selected: 'View all')
    expect(form).to have_button('Filter', class: 'btn-outline-primary')

    table = page.find("table#bulk-actions-history-table[aria-label='Bulk actions']")
    expect(table).to have_css('thead th:nth-of-type(1)', text: 'Bulk action')
    expect(table).to have_css('thead th:nth-of-type(2)', text: 'Action')
    expect(table).to have_css('thead th:nth-of-type(3)', text: 'Submitted')
    expect(table).to have_css('thead th', count: 7)
    expect(table).to have_no_css('thead th', text: 'User')
    expect(form).to have_no_select('Users')
    expect(table).to have_css('tbody tr', count: 2)

    bulk_action_row = table.find("tr##{dom_id(bulk_action, 'row')}")
    expect(bulk_action_row).to have_css("td:nth-of-type(1) a[href='/bulk_actions/#{bulk_action.id}']",
                                        text: "Bulk action #{bulk_action.id}: Test description")
    expect(bulk_action_row).to have_css('td:nth-of-type(2)', text: BulkActions::REINDEX.label)
    expect(bulk_action_row).to have_css('td:nth-of-type(3)', text: '2026-04-16 03:00:00 PT')
    expect(bulk_action_row).to have_css('td:nth-of-type(4)', text: 'Processing')
    expect(bulk_action_row).to have_no_css('td:nth-of-type(4) i.bi')
    expect(bulk_action_row).to have_css('td:nth-of-type(5)', text: '0 / 0 / 0')
    expect(bulk_action_row).to have_no_css('td:nth-of-type(6) a')
    expect(bulk_action_row).to have_no_css('td:nth-of-type(7) form')

    bulk_action_with_files_row = table.find("tr##{dom_id(bulk_action_with_files, 'row')}")
    expect(bulk_action_with_files_row)
      .to have_css("td:nth-of-type(1) a[href='/bulk_actions/#{bulk_action_with_files.id}']",
                   exact_text: "Bulk action #{bulk_action_with_files.id}")
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(2)', text: BulkActions::EXPORT_COCINA_JSON.label)
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(4)', text: 'Completed')
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(4) i.bi-exclamation-triangle-fill.text-warning')
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(5)', text: '7 / 5 / 2')
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(6) ul > li', count: 2)
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(6) a', text: 'Log')
    expect(bulk_action_with_files_row).to have_link(BulkActions::EXPORT_COCINA_JSON.exports.first.label)
    expect(bulk_action_with_files_row).to have_css(
      "td:nth-of-type(7) form[action='/bulk_actions/#{bulk_action_with_files.id}']" \
      "[data-turbo-confirm='Delete this bulk action from history? Its log and export files will also be deleted. " \
      "This cannot be undone.']"
    )
  end

  context 'when a bulk action has multiple export files' do
    let(:component) do
      described_class.new(bulk_actions: BulkAction.where(id: bulk_action.id).page(1).per(20), filter_form:)
    end

    let(:bulk_action) { create(:bulk_action, :with_export, action_type: :register_csv, status: :completed) }

    before do
      File.write(bulk_action.export_filepath(:tracking_sheets), 'PDF content')
    end

    it 'renders a link for each export file' do
      render_inline(component)

      row = page.find("tr##{dom_id(bulk_action, 'row')}")
      expect(row).to have_css('td:nth-of-type(6) ul > li', count: 2)
      expect(row).to have_css('td:nth-of-type(6) a', count: 2)
      expect(row).to have_link('Registration report',
                               href: "/bulk_actions/#{bulk_action.id}/file?filename=registration_report.csv")
      expect(row).to have_link('Tracking sheets',
                               href: "/bulk_actions/#{bulk_action.id}/file?filename=tracking_sheets.pdf")
    end
  end

  context 'when there are multiple pages' do
    before { create_list(:bulk_action, 5) }

    let(:component) do
      described_class.new(bulk_actions: BulkAction.all.page(2).per(2), filter_form:)
    end

    it 'renders pagination controls' do
      render_inline(component)

      expect(page).to have_css('nav.paginate-section')
      expect(page).to have_css('.page-item.active', text: '2')
      expect(page).to have_link('Next »', href: '/bulk_actions?page=3')
    end

    context 'when filtered' do
      let(:filter_form) do
        BulkActions::FilterForm.new(action_types: %w[REDEPOSIT], statuses: %w[completed], submitted_date: 'last_7_days')
      end

      it 'renders the selected action types and retains the filter in pagination links' do
        render_inline(component)

        expect(page).to have_css("select option[value='REDEPOSIT'][selected]")
        expect(page).to have_no_css("select option[value='REINDEX'][selected]")
        expect(page).to have_css("select option[value='completed'][selected]")
        expect(page).to have_no_css("select option[value='processing'][selected]")
        expect(page).to have_select('Submitted date', selected: 'Last 7 days')
        expect(page).to have_link('Next »',
                                  href: '/bulk_actions?bulk_actions_filter%5Baction_types%5D%5B%5D=REDEPOSIT' \
                                        '&bulk_actions_filter%5Bstatuses%5D%5B%5D=completed' \
                                        '&bulk_actions_filter%5Bsubmitted_date%5D=last_7_days&page=3')
      end
    end
  end

  context 'when an admin' do
    let(:filter_form) { BulkActions::FilterForm.new(user: admin_user, admin: true) }
    let(:admin_user) { create(:user, email_address: 'admin@stanford.edu') }
    let(:bulk_action) { create(:bulk_action, user: create(:user, email_address: 'mmouse@stanford.edu')) }

    it 'renders the users filter and the user column' do
      render_inline(component)

      expect(page).to have_css("select[multiple][data-controller='checkbox-tom-select'] " \
                               "option[value='#{admin_user.id}'][selected]", text: 'admin')
      expect(page).to have_css("select option[value='#{bulk_action.user_id}']:not([selected])", text: 'mmouse')

      table = page.find('table#bulk-actions-history-table')
      expect(table).to have_css('thead th', count: 8)
      expect(table).to have_css('thead th:nth-of-type(2)', text: 'User')

      row = table.find("tr##{dom_id(bulk_action, 'row')}")
      expect(row).to have_css('td:nth-of-type(2)', text: 'mmouse')
      expect(row).to have_css('td:nth-of-type(3)', text: BulkActions::REINDEX.label)
      expect(row).to have_no_css('td:nth-of-type(8) form')
    end
  end
end
