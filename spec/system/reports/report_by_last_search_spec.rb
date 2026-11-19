# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report by last search', :solr do
  let(:druid) { 'druid:hc000wh0120' }

  let(:headers) { %w[Druid PURL] }

  before do
    create(:solr_item, druid:)
    create_list(:solr_item, 2)
    sign_in(create(:user, :reader))
  end

  it 'returns a report' do
    visit search_path

    find_search_field.fill_in(with: 'test')
    click_button('Search')

    expect(page).to have_result_count(3)

    click_button('Reports')
    click_link('Druid report')

    # Report by last search is selected
    expect(page).to have_field('From last search', type: 'radio', checked: true)
    expect(page).to have_text('3 items for: "test"')
    expect(page).to have_link('hc000wh0120', href: '/objects/druid:hc000wh0120')

    expect(page).to have_field('Enter druid list', type: 'textarea', disabled: true, visible: :hidden)
    expect(page).to have_button('Download', disabled: false)
    expect(page).to have_no_button('Preview')

    # The preview of the default fields is shown on page load.
    within 'table#preview-table' do
      expect(page).to have_css('th', text: 'Title')
      expect(page).to have_css('tbody tr', count: 3)
    end

    choose 'From druid list'
    expect(page).to have_field('Enter druid list', type: 'textarea', disabled: false)
    expect(page).to have_button('Download', disabled: true)
    expect(page).to have_no_table('preview-table')

    choose 'From last search'
    expect(page).to have_field('Enter druid list', type: 'textarea', disabled: true, visible: :hidden)
    expect(page).to have_button('Download', disabled: false)
    expect(page).to have_css('table#preview-table tbody tr', count: 3)

    # Some checkboxes are selected
    expect(page).to have_field('report[fields][]', type: 'checkbox', checked: true)
    expect(page).to have_field('report[fields][]', type: 'checkbox', checked: false)

    # Select all sends one preview request, however many checkboxes it changes.
    preview_count = count_preview_requests do
      click_button 'Select all'
      # All checkboxes are selected
      expect(page).to have_no_field('report[fields][]', type: 'checkbox', checked: false)
      expect(page).to have_field('report[fields][]', type: 'checkbox', checked: true)
      expect(page).to have_css('table#preview-table th', text: 'DOI')
    end
    expect(preview_count).to eq(1)

    click_button 'Deselect all'
    expect(page).to have_no_field('report[fields][]', type: 'checkbox', checked: true)
    expect(page).to have_field('report[fields][]', type: 'checkbox', checked: false)
    expect(page).to have_button('Download', disabled: true)
    expect(page).to have_no_table('preview-table')

    # A burst of changes sends one preview request, which matches the final fields.
    # Fields are found first so the clicks come within the debounce of each other.
    druid_field, title_field, purl_field = %w[Druid Title PURL].map { |label| find_field(label) }
    preview_count = count_preview_requests do
      [druid_field, title_field, purl_field, title_field].each(&:click)

      within 'table#preview-table' do
        expect(page).to have_css('th', count: 2)
        headers.each do |header|
          expect(page).to have_css('th', text: header)
        end
        expect(page).to have_css('tbody tr', count: 3)
      end
    end
    expect(preview_count).to eq(1)

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

  # @return [Integer] the number of preview requests started while the block runs
  def count_preview_requests(&)
    count = 0
    callback = lambda do |event|
      count += 1 if event.payload[:controller] == 'ReportsController' && event.payload[:action] == 'preview'
    end
    ActiveSupport::Notifications.subscribed(callback, 'start_processing.action_controller', &)
    count
  end
end
