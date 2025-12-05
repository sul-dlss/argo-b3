# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report by druids', :solr do
  let!(:item_docs) { create_list(:solr_item, 3) }

  it 'returns a report' do
    visit report_path

    # Report by last search is disabled
    expect(page).to have_field('From last search', type: 'radio', disabled: true)

    expect(page).to have_field('From druid list', type: 'radio', checked: true)
    # Various separators, whitespace, and druid forms
    druids = "#{item_docs[0][Search::Fields::ID]}\n#{item_docs[1][Search::Fields::ID]} \t\t#{item_docs[2][Search::Fields::BARE_DRUID]} " # rubocop:disable Layout/LineLength
    fill_in 'Enter druid list', with: druids

    click_button 'Preview'

    within 'table#preview-table' do
      ReportsController::FREQUENTLY_USED_FIELDS.each do |config|
        expect(page).to have_css('th', text: config.label)
      end
      expect(page).to have_css('tbody tr', count: 3)
    end

    report_csv = with_download('report.csv') do
      click_button 'Download'
    end
    csv = CSV.parse(report_csv, headers: true)
    expect(csv.headers).to eq(ReportsController::FREQUENTLY_USED_FIELDS.map(&:label))
    expect(csv.length).to eq(3)
  end
end
