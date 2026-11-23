# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Advanced search', :solr do
  let(:user) { create(:user, :admin) }

  before do
    create(:solr_item, druid: 'druid:bc123df4567', title: 'Miller')
    create(:solr_collection, druid: 'druid:df234gh5678', title: 'octopus')
    sign_in(user)
  end

  it 'opens from the search bar and pins the search, which reopens from the dashboard' do
    visit search_path(query: 'Miller', object_types: ['item'])
    click_link 'Advanced search'

    expect(page).to have_current_path(advanced_search_path)
    expect(page).to have_no_css('#items-search')

    within('form[action="/advanced_search"]') do
      fill_in 'query', with: 'Miller OR octopus'
      click_button 'Search'
    end

    expect(page).to have_result_count(2)
    expect(find_search_field.value).to be_blank
    within(find_current_filters_section) { click_button 'Pin' }
    expect(page).to have_toast('Pin added')

    visit root_path
    click_link 'Advanced search ❯ Miller OR octopus'

    expect(page).to have_css('h1', text: 'Advanced search')
    expect(page).to have_field('query', with: 'Miller OR octopus')
    expect(page).to have_result_count(2)
  end

  it 'submits with Return and retains the Boolean query when refining with a facet' do
    visit advanced_search_path

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
    expect(page).to have_current_path('/advanced_search?advanced=true&query=Miller+OR+octopus&sort=title')

    find_facet_section('Object type').click
    within(find_facet_section('Object type')) do
      check 'item'
    end

    expect(page).to have_current_path(
      '/advanced_search?advanced=true&object_types%5B%5D=item&query=Miller+OR+octopus&sort=title'
    )
    expect(page).to have_result_count(1)
    expect(page).to have_current_filter('Miller OR octopus')
    expect(page).to have_current_filter('Object type', 'item')
  end

  it 'does not check facet values that appear in a field expression' do
    query = 'objectType_ssimdv:collection AND (Miller OR octopus)'
    visit advanced_search_path(query:)

    expect(page).to have_result_count(1)
    find_facet_section('Object type').click
    within(find_facet_section('Object type')) do
      expect(page).to have_unchecked_field('collection')
    end
  end
end
