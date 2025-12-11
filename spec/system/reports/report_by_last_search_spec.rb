# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report by druids', :solr do
  let(:druid) { 'druid:hc000wh0120' }

  let(:headers) { [Reports::Fields::DRUID.label, Reports::Fields::PURL.label] }

  before do
    create(:solr_item, druid:)
    create_list(:solr_item, 2)
  end

  it 'returns a report' do
    visit root_path

    find_search_field.fill_in(with: 'test')
    click_button('Search')

    expect(page).to have_result_count(3)

    click_link('Report')

    # Report by last search is selected
    expect(page).to have_field('From last search', type: 'radio', checked: true)
    expect(page).to have_content('3 items for: "test"')

    expect(page).to have_field('Enter druid list', type: 'textarea', disabled: true)

    choose 'From druid list'
    expect(page).to have_field('Enter druid list', type: 'textarea', disabled: false)

    choose 'From last search'
    expect(page).to have_field('Enter druid list', type: 'textarea', disabled: true)

    # Some checkboxes are selected
    expect(page).to have_field('report_form[fields][]', type: 'checkbox', checked: true)
    expect(page).to have_field('report_form[fields][]', type: 'checkbox', checked: false)

    click_link 'Select All'
    # All checkboxes are selected
    expect(page).to have_no_field('report_form[fields][]', type: 'checkbox', checked: false)
    expect(page).to have_field('report_form[fields][]', type: 'checkbox', checked: true)

    click_link 'Deselect All'
    expect(page).to have_no_field('report_form[fields][]', type: 'checkbox', checked: true)
    expect(page).to have_field('report_form[fields][]', type: 'checkbox', checked: false)
    expect(page).to have_button('Download', disabled: true)

    check 'Druid'
    check 'PURL'

    click_button 'Preview'

    within 'table#preview-table' do
      headers.each do |header|
        expect(page).to have_css('th', text: header)
      end
      expect(page).to have_css('tbody tr', count: 3)
    end

    report_csv = with_download('report.csv') do
      click_button 'Download'
    end
    csv = CSV.parse(report_csv, headers: true)
    expect(csv.headers).to eq(headers)
    expect(csv.length).to eq(3)
    expect(csv.first.to_h).to eq(
      {
        'Druid' => DruidSupport.bare_druid_from(druid),
        'PURL' => "https://purl.stanford.edu/#{DruidSupport.bare_druid_from(druid)}"
      }
    )
  end
end
