# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exclude facets', :solr do
  let!(:dark_item_doc) { create(:solr_item) }
  let!(:world_item_doc) { create(:solr_item, access_rights: 'world') }

  before do
    create_list(:solr_item, 3)
  end

  it 'returns facets' do
    visit search_items_path(query: 'test')

    expect(page).to have_css('h1', text: 'Items search page')

    expect(page).to have_result_count(5)
    expect(page).to have_item_result(world_item_doc)
    expect(page).to have_item_result(dark_item_doc)

    # Access rights is a non-lazy exclude facet.
    find_facet_section('Access rights').click
    expect(page).to have_facet_value('dark', count: 4, facet: 'Access rights')
    expect(page).to have_facet_value('world', count: 1, facet: 'Access rights')

    # Select a facet.
    within(find_facet_section('Access rights')) do
      click_link('Exclude world')
    end

    expect(page).to have_result_count(4)
    expect(page).to have_item_result(dark_item_doc)
    expect(page).not_to have_item_result(world_item_doc, wait: 0)

    expect(page).to have_current_filter('Access rights exclude', 'world')
    find_current_filter('Access rights exclude', 'world').click_link('Remove')

    expect(page).to have_result_count(5)
  end
end
