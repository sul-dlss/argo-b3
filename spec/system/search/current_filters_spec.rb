# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Current filters', :solr do
  let!(:item_doc) { create(:solr_item) }

  before do
    create(:solr_collection)
  end

  it 'returns current filters' do
    visit search_items_path(query: 'test')

    expect(page).to have_css('h1', text: 'Items search page')

    expect(page).to have_result_count(2)

    # Select a facet.
    within(find_facet_section('Object Types')) do
      click_link('item')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)
    expect(page).to have_current_filter('Object types', 'item')

    within(find_current_filters_section) do
      click_link('Remove')
    end

    expect(page).to have_result_count(2)
    expect(page).not_to have_current_filter('Object types', 'item', wait: 0)
  end
end
