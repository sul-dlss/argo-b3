# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Advanced search', :solr do
  before do
    create(:solr_item, druid: 'druid:bc123df4567', title: 'Miller')
    create(:solr_collection, druid: 'druid:df234gh5678', title: 'octopus')
    sign_in(create(:user, :admin))
  end

  it 'submits with Return and retains the Boolean query when refining with a facet' do
    visit search_path
    click_link 'Advanced search'

    within('form[action="/advanced_search"]') do
      fill_in 'query', with: 'Miller OR octopus'
      find_field('query').send_keys(:enter)
    end

    expect(page).to have_result_count(2)
    expect(page).to have_current_filter('Miller OR octopus')

    within(find_item_results_section) do
      click_link_or_button 'Sort by Relevance'
      click_link 'Title'
    end
    expect(page).to have_current_path(advanced_search_path(query: 'Miller OR octopus', sort: 'title'))

    find_facet_section('Object type').click
    within(find_facet_section('Object type')) do
      check 'item'
      click_button 'Filter'
    end

    expect(page).to have_current_path(
      advanced_search_path(query: 'Miller OR octopus', object_types: ['item'], sort: 'title')
    )
    expect(page).to have_result_count(1)
    expect(page).to have_current_filter('Miller OR octopus')
    expect(page).to have_current_filter('Object type', 'item')
    within(find_current_filters_section) do
      expect(page).to have_no_button('Pin')
    end
  end

  it 'does not check facet values that appear in a field expression' do
    query = 'objectType_ssimdv:collection AND (Miller OR octopus)'
    visit advanced_search_path(query:)

    expect(page).to have_result_count(1)
    expect(page).to have_current_filter(query)
    find_facet_section('Object type').click
    within(find_facet_section('Object type')) do
      expect(page).to have_unchecked_field('collection')
    end
    within(find_current_filters_section) do
      expect(page).to have_css('li', count: 1)
    end
  end
end
