# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Facets', :solr do
  let!(:item_doc) { create(:solr_item, :with_projects) }

  before do
    create(:solr_collection, :with_projects, projects: ['Project 1'])
    sign_in(create(:user, :reader))
  end

  it 'returns facets' do
    visit search_path(query: 'test')

    expect(page).to have_result_count(2)

    # Object type is a non-lazy checkbox facet.
    find_facet_section('Object type').click
    expect(page).to have_facet_value('collection', count: 1, facet: 'Object type')
    expect(page).to have_facet_value('item', count: 1, facet: 'Object type')

    # Select a facet.
    within(find_facet_section('Object type')) do
      check('item')
      click_button('Filter')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)
    expect(page).to have_current_filter('Object type', 'item')
    expect(page).to have_facet('Object type', expanded: true)

    find_facet_section('Project').click
    expect(page).to have_facet_value('Project 1', count: 1, facet: 'Project')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Project')

    expect(page).to have_selected_facet_value('item', facet: 'Object type')
    within(find_facet_section('Object type')) do
      uncheck('item')
      click_button('Filter')
    end

    expect(page).to have_result_count(2)
    expect(page).to have_facet('Object type', expanded: false)
    expect(page).not_to have_current_filter('Object type', 'item', wait: 0)

    # Project is a lazy facet.
    find_facet_section('Project').click
    expect(page).to have_facet_value('Project 1', count: 2, facet: 'Project')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Project')

    # Select a facet.
    within(find_facet_section('Project')) do
      click_link('Project 2')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)
    expect(page).to have_current_filter('Project', 'Project 2')

    expect(page).not_to have_facet_value('collection', count: 1, facet: 'Object type', wait: 0)

    expect(page).to have_facet('Project', expanded: true)
    expect(page).to have_selected_facet_value('Project 2', facet: 'Project')
    within(find_facet_section('Project')) do
      click_link('Remove')
    end

    expect(page).to have_result_count(2)
    expect(page).to have_facet('Project', expanded: false)
    expect(page).not_to have_current_filter('Project', 'Project 2', wait: 0)
  end
end
