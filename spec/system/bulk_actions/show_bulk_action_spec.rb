# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show a bulk action' do
  let(:user) { create(:user) }
  let(:bulk_action) do
    create(:bulk_action, user:, action_type: 'export_cocina_json', description: 'My bulk action')
  end

  before do
    FileUtils.rm_rf(Settings.bulk_actions.directory)

    sign_in(user)
  end

  it 'shows the bulk action details, refreshing until it is completed' do
    visit bulk_action_path(bulk_action)

    expect(page).to have_css('h1', text: BulkActions::EXPORT_COCINA_JSON.label)

    table = page.find('table#bulk-action-details-table')
    expect(table).to have_css('th', text: 'Submitted')
    expect(table).to have_css('td', text: 'My bulk action')
    expect(table).to have_css('td', text: 'Created')
    expect(table).to have_css('td', text: '0 / 0 / 0')
    expect(table).to have_no_css('th', text: 'Log file')

    # The spinner is shown while the bulk action is processing.
    expect(page).to have_css('img[alt="Spinner"]')
    expect(page).to have_text('Processing...')

    File.write(bulk_action.log_filepath, 'Log content')
    File.write(bulk_action.export_filepath, 'Export content')
    bulk_action.update!(status: :completed, druid_count_success: 1, druid_count_fail: 2, druid_count_total: 3)

    # The page refreshes on an interval, so the completed bulk action is shown without reloading.
    expect(page).to have_css('table#bulk-action-details-table td', text: 'Completed')
    expect(page).to have_css('table#bulk-action-details-table td', text: '3 / 1 / 2')

    # The spinner is removed once the bulk action is completed.
    expect(page).to have_no_css('img[alt="Spinner"]')
    expect(page).to have_no_text('Processing...')

    expect(page).to have_css('th', text: 'Log file')
    log_txt = with_download('log.txt') do
      click_link_or_button('log.txt')
    end
    expect(log_txt).to eq('Log content')

    expect(page).to have_css('th', text: BulkActions::EXPORT_COCINA_JSON.export_label)
    export_txt = with_download(BulkActions::EXPORT_COCINA_JSON.export_filename) do
      click_link_or_button(BulkActions::EXPORT_COCINA_JSON.export_filename)
    end
    expect(export_txt).to eq('Export content')
  end

  context 'when the bulk action has an export that should be shown' do
    let(:bulk_action) do
      create(:bulk_action, user:, action_type: 'register_csv', description: 'My registration',
                           status: :completed)
    end
    let(:export_content) do
      "Druid,Barcode,Folio Instance HRID,Source Id,Title\n" \
        "druid:bc123df4567,36105111111111,a1234,sul:1,First title\n"
    end

    before do
      File.write(bulk_action.export_filepath, export_content)
    end

    it 'shows the export as a table' do
      visit bulk_action_path(bulk_action)

      table = page.find('table#bulk-action-export-table')
      expect(table).to have_css('caption h2', text: BulkActions::REGISTER_CSV.export_label)
      expect(table).to have_css('thead th', text: 'Druid')
      expect(table).to have_css('thead th', text: 'Folio Instance HRID')
      expect(table).to have_css('tbody td', text: 'druid:bc123df4567')
      expect(table).to have_css('tbody td', text: 'First title')

      # The download link is still available.
      expect(page).to have_css('table#bulk-action-details-table td a', text: 'registration_report.csv')
    end
  end
end
