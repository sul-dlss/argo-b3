# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exclude facets', :solr do
  let!(:dark_item_doc) { create(:solr_item) }
  let!(:world_item_doc) { create(:solr_item, access_rights: 'world') }

  before do
    create_list(:solr_item, 3)
    sign_in(create(:user, :reader))
  end

  it 'returns facets' do
    visit search_path(query: 'test')

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

    expect(page).to have_facet('Access rights', expanded: true)
    expect(page).to have_excluded_facet_value('world', facet: 'Access rights')

    expect(page).to have_current_filter('Access rights exclude', 'world')
    find_current_filter('Access rights exclude', 'world').click_link('Remove')

    expect(page).to have_result_count(5)
  end

  context 'with a checkbox facet' do
    let!(:french_item_doc) { create(:solr_item, languages: ['French']) }

    it 'excludes and switches values' do
      visit search_path(query: 'test')

      expect(page).to have_result_count(6)
      find_facet_section('Language').click
      expect(page).to have_facet_value('English', count: 5, facet: 'Language')

      within(find_facet_section('Language')) { click_link('Exclude English') }

      expect(page).to have_result_count(1)
      expect(page).to have_item_result(french_item_doc)
      expect(page).to have_excluded_facet_value('English', facet: 'Language')
      expect(page).to have_current_filter('Language exclude', 'English')

      # Checking an excluded value stops excluding it.
      within(find_facet_section('Language')) { check('English') }

      expect(page).to have_result_count(5)
      expect(page).to have_current_filter('Language', 'English')
      expect(page).not_to have_current_filter('Language exclude', 'English', wait: 0)
      expect(page).to have_field('English', checked: true, focused: true)

      # Excluding a selected value deselects it.
      within(find_facet_section('Language')) { click_link('Exclude English') }

      expect(page).to have_result_count(1)
      expect(page).to have_excluded_facet_value('English', facet: 'Language')
      expect(page).not_to have_current_filter('Language', 'English', wait: 0)
    end
  end
end
