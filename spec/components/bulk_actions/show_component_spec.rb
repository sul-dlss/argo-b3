# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ShowComponent, type: :component do
  let(:component) { described_class.new(bulk_action:) }

  context 'when the bulk action is not completed' do
    let(:bulk_action) do
      create(:bulk_action, action_type: :reindex, description: 'Test description',
                           created_at: Time.zone.parse('2026-04-16T10:00:00Z'))
    end

    it 'renders the details and polls for updates' do
      render_inline(component)

      expect(page).to have_css('h1', text: BulkActions::REINDEX.label)
      expect(page).to have_css('div[data-controller="scheduled-refresh"]' \
                               '[data-scheduled-refresh-interval-value="500"]')
      expect(page).to have_css('img[alt="Spinner"]')
      expect(page).to have_text('Processing...')

      table = page.find('table#bulk-action-details-table')
      expect(table).to have_css('caption h2', text: 'Details')
      expect(table).to have_css('tr:nth-of-type(1) th', text: 'Submitted')
      expect(table).to have_css('tr:nth-of-type(1) td', text: '2026-04-16 03:00:00 PT')
      expect(table).to have_css('tr:nth-of-type(2) th', text: 'Description')
      expect(table).to have_css('tr:nth-of-type(2) td', text: 'Test description')
      expect(table).to have_css('tr:nth-of-type(3) th', text: 'Status')
      expect(table).to have_css('tr:nth-of-type(3) td', text: 'Created')
      expect(table).to have_css('tr:nth-of-type(4) th', text: 'Total / Success / Failed')
      expect(table).to have_css('tr:nth-of-type(4) td', text: '0 / 0 / 0')
      expect(table).to have_css('tbody tr', count: 4)
    end
  end

  context 'when the bulk action is completed with log and export files' do
    let(:bulk_action) do
      create(:bulk_action, :with_log, :with_export,
             action_type: :export_cocina_json,
             status: :completed,
             druid_count_success: 5, druid_count_fail: 2, druid_count_total: 7)
    end

    it 'renders the file links and does not poll for updates' do
      render_inline(component)

      expect(page).to have_no_css('div[data-controller="scheduled-refresh"]')
      expect(page).to have_no_css('img[alt="Spinner"]')

      table = page.find('table#bulk-action-details-table')
      expect(table).to have_css('tr:nth-of-type(3) td', text: 'Completed')
      expect(table).to have_css('tr:nth-of-type(4) td', text: '7 / 5 / 2')
      expect(table).to have_css('tr:nth-of-type(5) th', text: 'Log file')
      expect(table).to have_css(
        "tr:nth-of-type(5) td a[href='/bulk_actions/#{bulk_action.id}/file?filename=log.txt'][download]",
        text: 'log.txt'
      )
      expect(table).to have_css('tr:nth-of-type(6) th', text: bulk_action.export_label)
      expect(table).to have_css(
        "tr:nth-of-type(6) td a[href='/bulk_actions/#{bulk_action.id}/" \
        "file?filename=#{bulk_action.export_filename}'][download]",
        text: bulk_action.export_filename
      )
      expect(table).to have_css('tbody tr', count: 6)
      expect(page).to have_no_table('bulk-action-export-table')
    end
  end

  context 'when the bulk action is completed with an export that should be shown' do
    let(:export_content) do
      "Druid,Barcode,Folio Instance HRID,Source Id,Title\n" \
        "druid:bc123df4567,36105111111111,a1234,sul:1,First title\n" \
        ",,,sul:2,Second title\n"
    end
    let(:bulk_action) do
      create(:bulk_action, :with_export,
             action_type: :register_csv,
             status: :completed,
             export_content:)
    end

    it 'renders the export as a data table' do
      render_inline(component)

      table = page.find('table#bulk-action-export-table')
      expect(table[:class]).to include('table-data')
      expect(table).to have_css('caption h2', text: BulkActions::REGISTER_CSV.export_label)
      expect(table).to have_css('thead th', count: 5)
      expect(table).to have_css('thead th:nth-of-type(1)', text: 'Druid')
      expect(table).to have_css('thead th:nth-of-type(2)', text: 'Barcode')
      expect(table).to have_css('thead th:nth-of-type(3)', text: 'Folio Instance HRID')
      expect(table).to have_css('thead th:nth-of-type(4)', text: 'Source Id')
      expect(table).to have_css('thead th:nth-of-type(5)', text: 'Title')
      expect(table).to have_css('tbody tr', count: 2)
      expect(table).to have_css('tbody tr:nth-of-type(1) td', count: 5)
      expect(table).to have_css('tbody tr:nth-of-type(1) td:nth-of-type(1)', text: 'druid:bc123df4567')
      expect(table).to have_css('tbody tr:nth-of-type(1) td:nth-of-type(5)', text: 'First title')
      # The druid is blank for a failed registration, but the row still has a cell for every column.
      expect(table).to have_css('tbody tr:nth-of-type(2) td', count: 5)
      expect(table).to have_css('tbody tr:nth-of-type(2) td:nth-of-type(5)', text: 'Second title')
    end
  end
end
