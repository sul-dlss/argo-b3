# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report by druids', :solr do
  let!(:item_docs) { create_list(:solr_item, 3) }

  before do
    sign_in(create(:user, :reader))
  end

  # The preview is requested with JavaScript, so check that it sends a valid authenticity token.
  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it 'returns a report' do
    visit report_path

    # Report by last search is disabled
    expect(page).to have_field('From last search', type: 'radio', disabled: true)

    expect(page).to have_field('From druid list', type: 'radio', checked: true)
    expect(page).to have_button('Download (opens in new tab)', disabled: true)
    expect(page).to have_css('button[formtarget="_blank"] i.bi-box-arrow-up-right[aria-hidden="true"]')
    expect(page).to have_no_button('Preview')
    expect(page).to have_css('h2', text: 'Preview')
    # No preview without druids
    expect(page).to have_no_table('preview-table')

    # Various separators, whitespace, and druid forms
    druids = "#{item_docs[0][Search::Fields::ID]}\n#{item_docs[1][Search::Fields::ID]} \t\t#{item_docs[2][Search::Fields::BARE_DRUID]} " # rubocop:disable Layout/LineLength
    fill_in 'Enter druid list', with: druids

    expect(page).to have_button('Download', disabled: false)
    # The preview waits until the druid list loses focus.
    expect(page).to have_no_table('preview-table')
    find_field('Enter druid list').send_keys(:tab)

    # The preview refreshes without a button click.
    within 'table#preview-table' do
      ReportsController::FREQUENTLY_USED_FIELDS.each do |config|
        expect(page).to have_css('th', text: config.label)
      end
      expect(page).to have_css('tbody tr', count: 3)
    end
    expect(page).to have_css('[role="status"]', text: 'Preview updated.', visible: :all)

    # Clearing the druid list clears the preview.
    fill_in 'Enter druid list', with: ''
    find_field('Enter druid list').send_keys(:tab)
    expect(page).to have_no_table('preview-table')
    expect(page).to have_css('[role="status"]', text: 'Preview cleared.', visible: :all)

    fill_in 'Enter druid list', with: druids
    find_field('Enter druid list').send_keys(:tab)
    expect(page).to have_css('table#preview-table tbody tr', count: 3)

    report_csv = with_download('report.csv') do
      click_button 'Download'
    end
    csv = CSV.parse(report_csv, headers: true)
    expect(csv.headers).to eq(ReportsController::FREQUENTLY_USED_FIELDS.map(&:label))
    expect(csv.length).to eq(3)
  end
end
