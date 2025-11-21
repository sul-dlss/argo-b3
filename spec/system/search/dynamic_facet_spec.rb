# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dynamic facets', :solr do
  let!(:released_item_doc) { create(:solr_item) }
  let!(:not_released_item_doc) { create(:solr_item, released_to_earthworks: false) }

  before do
    create_list(:solr_item, 4)
    create_list(:solr_item, 3, released_to_earthworks: false)
  end

  it 'returns facets' do
    visit search_items_path(query: 'test')

    expect(page).to have_css('h1', text: 'Items search page')

    expect(page).to have_result_count(9)

    # Released to Earthworks is a dynamic facet.
    find_facet_section('Released to Earthworks').click
    expect(page).to have_facet_value('Last week', count: 5, facet: 'Released to Earthworks')
    expect(page).to have_facet_value('Last month', count: 5, facet: 'Released to Earthworks')
    expect(page).to have_facet_value('Last year', count: 5, facet: 'Released to Earthworks')
    expect(page).to have_facet_value('Currently released', count: 5, facet: 'Released to Earthworks')
    expect(page).to have_facet_value('Not released', count: 4, facet: 'Released to Earthworks')

    within(find_facet_section('Released to Earthworks')) do
      click_link('Currently released')
    end

    expect(page).to have_result_count(5)
    expect(page).to have_item_result(released_item_doc)
    expect(page).not_to have_item_result(not_released_item_doc)
    expect(page).to have_current_filter('Released to Earthworks', 'Currently released')
    expect(page).to have_facet('Released to Earthworks', expanded: true)

    within(find_facet_section('Released to Earthworks')) do
      click_link('Remove')
    end

    expect(page).to have_result_count(9)
    expect(page).to have_facet('Released to Earthworks', expanded: false)
    expect(page).not_to have_current_filter('Released to Earthworks', 'Currently released', wait: 0)
  end
end
