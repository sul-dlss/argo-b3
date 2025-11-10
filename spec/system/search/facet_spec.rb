# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Facets', :solr do
  let!(:item_doc) { create(:solr_item, :with_projects) }

  before do
    create(:solr_collection, :with_projects, projects: ['Project 1'])
  end

  it 'returns facets' do
    visit search_items_path(query: 'test')

    expect(page).to have_css('h1', text: 'Items search page')

    expect(page).to have_result_count(2)

    # Object types is a non-lazy facet.
    expect(page).to have_facet_value('collection', count: 1, facet: 'Object Types')
    expect(page).to have_facet_value('item', count: 1, facet: 'Object Types')

    # Select a facet.
    within(find_facet_section('Object Types')) do
      click_link('item')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)

    expect(page).to have_facet_value('Project 1', count: 1, facet: 'Projects')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Projects')

    expect(page).to have_selected_facet_value('item', facet: 'Object Types')
    click_link('Remove')

    expect(page).to have_result_count(2)

    # Projects is a lazy facet.
    expect(page).to have_facet_value('Project 1', count: 2, facet: 'Projects')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Projects')

    # Select a facet.
    within(find_facet_section('Projects')) do
      click_link('Project 2')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)

    expect(page).not_to have_facet_value('collection', count: 1, facet: 'Object Types', wait: 0)

    expect(page).to have_selected_facet_value('Project 2', facet: 'Projects')
    click_link('Remove')

    expect(page).to have_result_count(2)
  end
end
