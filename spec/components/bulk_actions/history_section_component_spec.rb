# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::HistorySectionComponent, type: :component do
  include ActionView::RecordIdentifier

  let(:component) do
    described_class.new(bulk_actions: [bulk_action, bulk_action_with_files])
  end

  let(:bulk_action) { create(:bulk_action, action_type: :reindex, description: 'Test description') }
  let(:bulk_action_with_files) do
    create(:bulk_action, :with_log, :with_export,
           action_type: :export_cocina_json,
           status: :completed,
           druid_count_success: 5, druid_count_fail: 2, druid_count_total: 7)
  end

  it 'renders the history section with bulk actions' do
    render_inline(component)

    expect(page).to have_css('h1', text: 'Bulk actions history')

    table = page.find("table#bulk-actions-history-table[aria-label='Bulk actions history']")
    expect(table).to have_css('thead th', text: 'Submitted')
    expect(table).to have_css('thead th', count: 8)
    expect(table).to have_css('tbody tr', count: 2)

    bulk_action_row = table.find("tr##{dom_id(bulk_action, 'row')}")
    expect(bulk_action_row).to have_css('td:nth-of-type(2)', text: BulkActions::REINDEX.label)
    expect(bulk_action_row).to have_css('td:nth-of-type(3)', text: 'Test description')
    expect(bulk_action_row).to have_css('td:nth-of-type(4)', text: 'Created')
    expect(bulk_action_row).to have_css('td:nth-of-type(5)', text: '0 / 0 / 0')
    expect(bulk_action_row).to have_no_css('td:nth-of-type(6) a', text: 'Log')
    expect(bulk_action_row).to have_css('td:nth-of-type(7)', text: '')
    expect(bulk_action_row).to have_css('td:nth-of-type(8) form button[type="submit"]', text: 'Delete')

    bulk_action_with_files_row = table.find("tr##{dom_id(bulk_action_with_files, 'row')}")
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(2)', text: BulkActions::EXPORT_COCINA_JSON.label)
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(3)', text: '')
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(4)', text: 'Completed')
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(5)', text: '7 / 5 / 2')
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(6) a', text: 'Log')
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(7) a', text: BulkActions::EXPORT_COCINA_JSON.export_label)
    expect(bulk_action_with_files_row).to have_css('td:nth-of-type(8) form button[type="submit"]', text: 'Delete')
  end
end
