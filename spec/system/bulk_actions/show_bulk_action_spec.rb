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
    expect(page).to have_css('.object-type-bulk-action span.object-type-bg', text: /bulk action/i)

    expect(page).to have_css('h2', text: 'Processing')
    expect(page).to have_text('My bulk action')
    expect(page).to have_css('h2', text: 'Total / Success / Failed')
    expect(page).to have_css('.show-box', text: '0 / 0 / 0')
    expect(page).to have_no_css('h2', text: 'Downloads')

    File.write(bulk_action.log_filepath, 'Log content')
    File.write(bulk_action.export_filepath(:cocina_json), 'Export content')
    bulk_action.update!(status: :completed, druid_count_success: 1, druid_count_fail: 2, druid_count_total: 3)

    # The page refreshes on an interval, so the completed bulk action is shown without reloading.
    expect(page).to have_css('h2', text: 'Completed with errors')
    expect(page).to have_css('.show-box', text: '3 / 1 / 2')

    expect(page).to have_link('Log file')
    log_txt = with_download('log.txt') do
      click_link_or_button('Log file')
    end
    expect(log_txt).to eq('Log content')

    expect(page).to have_link('Cocina JSON')
    export_txt = with_download('cocina.jsonl.gz') do
      click_link_or_button('Cocina JSON')
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
      File.write(bulk_action.export_filepath(:registration_report), export_content)
    end

    it 'shows the export as a table in a tab labeled with the export label' do
      visit bulk_action_path(bulk_action)

      expect(page).to have_button('Registration report')
      expect(page).to have_no_button('Export')

      table = page.find('table#bulk-action-registration-report-table')
      expect(table).to have_css('thead th', text: 'Druid')
      expect(table).to have_css('thead th', text: 'Folio Instance HRID')
      expect(table).to have_css('tbody td', text: 'druid:bc123df4567')
      expect(table).to have_css('tbody td', text: 'First title')

      # The download link is still available.
      expect(page).to have_link('Registration report')
    end
  end
end
