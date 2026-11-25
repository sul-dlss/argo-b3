# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Year range facet', :solr do
  let!(:bce_item_doc) { create(:solr_item, dates: ['-10']) }
  let!(:early_item_doc) { create(:solr_item, dates: ['201']) }
  let!(:recent_item_doc) { create(:solr_item, dates: ['2010']) }

  before do
    sign_in(create(:user, :reader))
  end

  it 'filters by a range of years' do
    visit search_path(query: 'test')

    expect(page).to have_result_count(3)

    find_facet_section('Year').click
    expect(page).to have_facet_value('2010', count: 1, facet: 'Year')

    within(find_facet_section('Year')) do
      fill_in 'From', with: '2000'
      fill_in 'To', with: '2020'
      click_button 'Filter'
    end

    # A string range would also match 201.
    expect(page).to have_result_count(1)
    expect(page).to have_item_result(recent_item_doc)
    expect(page).not_to have_item_result(early_item_doc, wait: 0)

    expect(page).to have_current_filter('Year from', '2000')
    expect(page).to have_current_filter('Year to', '2020')
    expect(page).to have_facet('Year', expanded: true)
    expect(page).to have_field('From', with: '2000')
    expect(page).to have_field('To', with: '2020')

    within(find_current_filters_section) do
      click_link('Remove Year from')
    end

    expect(page).to have_result_count(3)
    expect(page).not_to have_current_filter('Year from', '2000', wait: 0)
    expect(page).to have_current_filter('Year to', '2020')

    within(find_facet_section('Year')) do
      fill_in 'To', with: '0'
      click_button 'Filter'
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(bce_item_doc)
  end
end
