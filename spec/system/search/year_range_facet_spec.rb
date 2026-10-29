# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Year range facet', :solr do
  let!(:early_item_doc) { create(:solr_item, dates: ['201']) }
  let!(:recent_item_doc) { create(:solr_item, dates: ['2010']) }

  before do
    sign_in(create(:user, :reader))
  end

  it 'filters by a range of years' do
    visit search_path(query: 'test')

    expect(page).to have_result_count(2)

    find_facet_section('Year').click
    expect(page).to have_facet_value('201', count: 1, facet: 'Year')
    expect(page).to have_facet_value('2010', count: 1, facet: 'Year')

    within(find_facet_section('Year')) do
      fill_in 'From', with: '2000'
      fill_in 'To', with: '2020'
      click_button 'Filter'
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(recent_item_doc)
    expect(page).not_to have_item_result(early_item_doc, wait: 0)

    expect(page).to have_current_filter('Year from', '2000')
    expect(page).to have_current_filter('Year to', '2020')
    expect(page).to have_facet('Year', expanded: true)
    expect(page).to have_field('From', with: '2000')
    expect(page).to have_field('To', with: '2020')

    # Change the range.
    within(find_facet_section('Year')) do
      fill_in 'From', with: '1'
      click_button 'Filter'
    end

    expect(page).to have_result_count(2)
    expect(page).to have_current_filter('Year from', '1')
    expect(page).to have_current_filter('Year to', '2020')

    # Filtering with another facet's form retains the range.
    find_facet_section('Object type').click
    within(find_facet_section('Object type')) do
      check('item')
      click_button('Filter')
    end

    expect(page).to have_current_filter('Object type', 'item')
    expect(page).to have_current_filter('Year from', '1')
    expect(page).to have_current_filter('Year to', '2020')
    within(find_current_filters_section) do
      click_link('Remove Object type > item')
    end
    expect(page).not_to have_current_filter('Object type', 'item', wait: 0)

    within(find_current_filters_section) do
      click_link('Remove Year from')
    end
    expect(page).to have_result_count(2)

    within(find_current_filters_section) do
      click_link('Remove Year to')
    end
    expect(page).to have_result_count(2)
    expect(page).not_to have_current_filter('Year to', '2020', wait: 0)
  end
end
