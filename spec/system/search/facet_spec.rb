# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Facets', :solr do
  let!(:item_doc) { create(:solr_item, :with_projects) }

  before do
    create(:solr_collection, :with_projects, projects: ['Project 1'])
    create(:solr_collection,
           druid: item_doc.fetch(Search::Fields::COLLECTION_DRUIDS).first,
           title: item_doc.fetch(Search::Fields::COLLECTION_TITLES).first)
    create(:solr_collection,
           druid: item_doc.fetch(Search::Fields::APO_DRUID).first,
           title: item_doc.fetch(Search::Fields::APO_TITLE).first,
           object_type: 'APO')
    sign_in(create(:user, :reader))
  end

  it 'returns facets' do
    visit search_path(query: 'test')

    expect(page).to have_result_count(2)

    # Object types is a non-lazy checkbox facet.
    find_facet_section('Object types').click
    expect(page).to have_facet_value('collection', count: 1, facet: 'Object types')
    expect(page).to have_facet_value('item', count: 1, facet: 'Object types')

    # Select a facet.
    within(find_facet_section('Object types')) do
      check('item')
      click_button('Filter')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)
    expect(page).to have_current_filter('Object types', 'item')
    expect(page).to have_facet('Object types', expanded: true)

    find_facet_section('Projects').click
    expect(page).to have_facet_value('Project 1', count: 1, facet: 'Projects')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Projects')

    expect(page).to have_selected_facet_value('item', facet: 'Object types')
    within(find_facet_section('Object types')) do
      uncheck('item')
      click_button('Filter')
    end

    expect(page).to have_result_count(2)
    expect(page).to have_facet('Object types', expanded: false)
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

    expect(page).not_to have_facet_value('collection', count: 1, facet: 'Object types', wait: 0)

    expect(page).to have_facet('Projects', expanded: true)
    expect(page).to have_selected_facet_value('Project 2', facet: 'Projects')
    within(find_facet_section('Projects')) do
      click_link('Remove')
    end

    expect(page).to have_result_count(2)
    expect(page).to have_facet('Projects', expanded: false)
    expect(page).not_to have_current_filter('Projects', 'Project 2', wait: 0)
  end

  it 'displays collection titles while filtering by collection druid' do
    collection_druid = item_doc.fetch(Search::Fields::COLLECTION_DRUIDS).first
    collection_title = item_doc.fetch(Search::Fields::COLLECTION_TITLES).first

    visit search_path(query: 'test')

    find_facet_section('Collections').click
    expect(page).to have_facet_value(collection_title, count: 1, facet: 'Collections')

    within(find_facet_section('Collections')) do
      click_link(collection_title)
    end

    expect(page).to have_current_filter('Collections', collection_title)
    expect(page).to have_result_count(1)
    expect(page).to have_item_result(item_doc)
    query_params = Rack::Utils.parse_nested_query(URI.parse(page.current_url).query)
    expect(query_params.fetch('collection_druids')).to eq([collection_druid])
  end
end
