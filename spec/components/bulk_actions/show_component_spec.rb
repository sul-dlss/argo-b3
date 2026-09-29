# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ShowComponent, type: :component do
  let(:component) { described_class.new(bulk_action:) }

  context 'when the bulk action is not completed' do
    let(:bulk_action) do
      create(:bulk_action, action_type: :reindex, description: 'Test description',
                           updated_at: Time.zone.parse('2026-04-16T10:00:00Z'))
    end

    it 'renders the pill, boxes, and polls for updates, without tabs' do
      render_inline(component)

      expect(page).to have_link('← Bulk action', href: '/bulk_actions')
      expect(page).to have_css('h1', text: BulkActions::REINDEX.label)
      expect(page).to have_css('.object-type-bulk-action span.object-type-bg', text: 'Bulk action')
      expect(page).to have_css('div[data-controller="scheduled-refresh"]' \
                               '[data-scheduled-refresh-interval-value="500"]')

      status_box = page.first('.show-box')
      expect(status_box).to have_css('h2', text: 'Processing')
      expect(status_box).to have_no_css('i.bi')
      expect(status_box).to have_css('p', text: '2026-04-16 03:00:00 PT')
      expect(status_box).to have_css('p', text: 'Test description')

      expect(page).to have_css('h2', text: 'Total / Success / Failed')
      expect(page).to have_css('.show-box', text: '0 / 0 / 0')

      expect(page).to have_no_css('h2', text: 'Downloads')
      expect(page).to have_no_css('[role="tablist"]')
    end
  end

  context 'when the bulk action is completed with log and export files' do
    let(:bulk_action) do
      create(:bulk_action, :with_log, :with_export,
             action_type: :export_cocina_json,
             status: :completed,
             druid_count_success: 5, druid_count_fail: 0, druid_count_total: 5)
    end

    it 'renders a success status and download links, but no tabs' do
      render_inline(component)

      expect(page).to have_no_css('div[data-controller="scheduled-refresh"]')

      expect(page).to have_css('h2 i.bi-check-circle-fill.text-success')
      expect(page).to have_css('h2', text: 'Completed')

      downloads_box = page.find('h2', text: 'Downloads').ancestor('.card')
      expect(downloads_box).to have_link('Log file',
                                         href: "/bulk_actions/#{bulk_action.id}/file?filename=log.txt")
      expect(downloads_box).to have_link('Cocina JSON',
                                         href: "/bulk_actions/#{bulk_action.id}/file?filename=cocina.jsonl.gz")

      expect(page).to have_no_css('[role="tablist"]')
    end
  end

  context 'when the bulk action is completed with errors' do
    let(:log_content) do
      "2026-04-16 03:00:00 PT\tline 2\tdruid:bc123df4567\tSuccess: Did the thing\n" \
        "2026-04-16 03:00:00 PT\tline 3\tdruid:df456gh7890\tError: Something went wrong\n"
    end
    let(:bulk_action) do
      create(:bulk_action, :with_log,
             action_type: :reindex,
             status: :completed,
             log_content:,
             druid_count_success: 1, druid_count_fail: 1, druid_count_total: 2)
    end

    it 'renders a "complete with errors" status and an active Errors tab' do
      render_inline(component)

      expect(page).to have_css('h2 i.bi-exclamation-triangle-fill.text-warning')
      expect(page).to have_css('h2', text: 'Completed with errors')

      expect(page).to have_button('Errors', class: 'active')
      expect(page).to have_css('pre', text: 'Error: Something went wrong')
      expect(page).to have_no_css('pre', text: 'Success: Did the thing')
    end
  end

  context 'when the bulk action is completed with an export that should be shown' do
    let(:export_content) do
      "Druid,Barcode,Folio Instance HRID,Source Id,Title\n" \
        "druid:bc123df4567,36105111111111,a1234,sul:1,First title\n" \
        ",,,sul:2,Second title\n" \
        "hj456kl7890,,,sul:3,Third title\n"
    end
    let(:bulk_action) do
      create(:bulk_action, :with_export,
             action_type: :register_csv,
             status: :completed,
             export_content:)
    end

    it 'renders the export as an active, labeled tab, and as a download link' do
      render_inline(component)

      expect(page).to have_button('Registration report', class: 'active')
      expect(page).to have_no_button('Export')

      table = page.find('table#bulk-action-registration-report-table')
      expect(table).to have_css('thead th', count: 5)
      expect(table).to have_css('thead th:nth-of-type(1)', text: 'Druid')
      expect(table).to have_css('thead th:nth-of-type(2)', text: 'Barcode')
      expect(table).to have_css('thead th:nth-of-type(3)', text: 'Folio Instance HRID')
      expect(table).to have_css('thead th:nth-of-type(4)', text: 'Source Id')
      expect(table).to have_css('thead th:nth-of-type(5)', text: 'Title')
      expect(table).to have_css('tbody tr', count: 3)
      expect(table).to have_css('tbody tr:nth-of-type(1) td', count: 5)
      expect(table).to have_css("tbody tr:nth-of-type(1) td:nth-of-type(1) a[href='/objects/druid:bc123df4567']",
                                text: 'druid:bc123df4567')
      expect(table).to have_css('tbody tr:nth-of-type(1) td:nth-of-type(5)', text: 'First title')
      # The druid is blank for a failed registration, but the row still has a cell for every column.
      expect(table).to have_css('tbody tr:nth-of-type(2) td', count: 5)
      expect(table).to have_css('tbody tr:nth-of-type(2) td:nth-of-type(5)', text: 'Second title')
      expect(table).to have_no_css('tbody tr:nth-of-type(2) td:nth-of-type(1) a')
      # A bare druid is linked as a full druid.
      expect(table).to have_css("tbody tr:nth-of-type(3) td:nth-of-type(1) a[href='/objects/druid:hj456kl7890']",
                                text: 'druid:hj456kl7890')

      downloads_box = page.find('h2', text: 'Downloads').ancestor('.card')
      expect(downloads_box).to have_link('Registration report',
                                         href: "/bulk_actions/#{bulk_action.id}/file?filename=registration_report.csv")
    end
  end

  context 'when the export has a lowercase druid header' do
    let(:export_content) { "druid,Title\ndruid:mn789pq1234,First title\n" }
    let(:bulk_action) do
      create(:bulk_action, :with_export,
             action_type: :register_csv,
             status: :completed,
             export_content:)
    end

    it 'links the druid to the object show page' do
      render_inline(component)

      table = page.find('table#bulk-action-registration-report-table')
      expect(table).to have_css("tbody td:nth-of-type(1) a[href='/objects/druid:mn789pq1234']",
                                text: 'druid:mn789pq1234')
      expect(table).to have_no_css('tbody td:nth-of-type(2) a')
    end
  end

  context 'when the bulk action is completed with multiple export files' do
    let(:bulk_action) do
      create(:bulk_action, :with_export,
             action_type: :register_csv,
             status: :completed,
             export_content: "Druid,Barcode,Folio Instance HRID,Source Id,Title\n")
    end

    before do
      File.write(bulk_action.export_filepath(:tracking_sheets), 'PDF content')
    end

    it 'renders a row for each export file and a table only for the shown export' do
      render_inline(component)

      table = page.find('table#bulk-action-details-table')
      expect(table).to have_css('tr:nth-of-type(5) th', text: 'Registration report')
      expect(table).to have_css('tr:nth-of-type(5) td a', text: 'registration_report.csv')
      expect(table).to have_css('tr:nth-of-type(6) th', text: 'Tracking sheets')
      expect(table).to have_css(
        "tr:nth-of-type(6) td a[href='/bulk_actions/#{bulk_action.id}/file?filename=tracking_sheets.pdf'][download]",
        text: 'tracking_sheets.pdf'
      )

      expect(page).to have_table('bulk-action-registration-report-table')
      expect(page).to have_no_table('bulk-action-tracking-sheets-table')
    end
  end
end
