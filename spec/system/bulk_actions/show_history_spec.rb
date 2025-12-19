# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show bulk actions history' do
  include ActionView::RecordIdentifier

  # This bulk action is owned by a different user, so should not appear in the list.
  let!(:bulk_action_other_user) { create(:bulk_action) }
  let(:user) { create(:user) }

  before do
    FileUtils.rm_rf(Settings.bulk_actions.directory)

    sign_in(user)
  end

  it 'shows the bulk actions for the current user' do
    visit bulk_actions_path

    expect(page).to have_css('h1', text: 'Bulk actions history')

    expect(page).to have_table('bulk-actions-history-table')
    expect(page).to have_no_css('table#bulk-actions-history-table tbody tr')
    expect(page).to have_css('p', text: 'No bulk actions.')

    bulk_action = create(:bulk_action, :with_log, :with_export, user:, description: 'First bulk action',
                                                                action_type: 'export_cocina_json')

    row = page.find("tr##{dom_id(bulk_action, 'row')}")
    expect(row).to have_css('td:nth-of-type(3)', text: 'First bulk action')
    expect(row).to have_css('td:nth-of-type(5)', text: '0 / 0 / 0')
    expect(page).to have_css("tr##{dom_id(bulk_action, 'row')}", text: 'First bulk action')
    expect(page).to have_no_css('p', text: 'No bulk actions.')
    expect(page).to have_no_css("tr##{dom_id(bulk_action_other_user, 'row')}")

    bulk_action.update!(druid_count_success: 1, druid_count_fail: 2, druid_count_total: 3)

    expect(row).to have_css('td:nth-of-type(5)', text: '3 / 1 / 2')

    expect(row).to have_css('td:nth-of-type(6) a', text: 'Log')
    log_txt = with_download('log.txt') do
      row.click_link('Log')
    end
    expect(log_txt).to eq('Log content')

    expect(row).to have_css('td:nth-of-type(7) a', text: BulkActions::EXPORT_COCINA_JSON.export_label)
    export_txt = with_download(BulkActions::EXPORT_COCINA_JSON.export_filename) do
      row.click_link(BulkActions::EXPORT_COCINA_JSON.export_label)
    end
    expect(export_txt).to eq('Export content')

    accept_confirm do
      row.click_button('Delete')
    end

    expect(page).to have_css('p', text: 'No bulk actions.')
    expect(page).to have_toast("#{bulk_action.label} deleted")

    expect(BulkAction.exists?(bulk_action.id)).to be false
  end
end
