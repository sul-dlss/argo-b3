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

    # Object types is a non-lazy checkbox facet.
    find_facet_section('Object Types').click
    expect(page).to have_facet_value('collection', count: 1, facet: 'Object Types')
    expect(page).to have_facet_value('item', count: 1, facet: 'Object Types')

    # Select a facet.
    within(find_facet_section('Object Types')) do
      check('item')
      click_button('Filter')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)
    expect(page).to have_current_filter('Object types', 'item')
    expect(page).to have_facet('Object Types', expanded: true)

    find_facet_section('Projects').click
    expect(page).to have_facet_value('Project 1', count: 1, facet: 'Projects')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Projects')

    expect(page).to have_selected_facet_value('item', facet: 'Object Types')
    within(find_facet_section('Object Types')) do
      uncheck('item')
      click_button('Filter')
    end

    expect(page).to have_result_count(2)
    expect(page).to have_facet('Object Types', expanded: false)
    expect(page).not_to have_current_filter('Object types', 'item', wait: 0)

    # Projects is a lazy facet.
    find_facet_section('Projects').click
    expect(page).to have_facet_value('Project 1', count: 2, facet: 'Projects')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Projects')

    # Select a facet.
    within(find_facet_section('Projects')) do
      click_link('Project 2')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)
    expect(page).to have_current_filter('Projects', 'Project 2')

    expect(page).not_to have_facet_value('collection', count: 1, facet: 'Object Types', wait: 0)

    expect(page).to have_facet('Projects', expanded: true)
    expect(page).to have_selected_facet_value('Project 2', facet: 'Projects')
    within(find_facet_section('Projects')) do
      click_link('Remove')
    end

    expect(page).to have_result_count(2)
    expect(page).to have_facet('Projects', expanded: false)
    expect(page).not_to have_current_filter('Projects', 'Project 2', wait: 0)
  end
end
