# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Facet search', :solr do
  before do
    create(:solr_item, :with_tags)
    create(:solr_collection, :with_tags, tags: ['Tag 1'])
  end

  it 'searches facets' do
    visit search_items_path(query: 'test')

    assert_item_search_page

    expect(page).to have_result_count(2)

    find_facet_section('Tags').click
    expect(page).to have_facet_value('Tag 1', count: 2, facet: 'Tags')
    expect(page).to have_facet_value('Tag 2', count: 1, facet: 'Tags')

    fill_in('Search these tags', with: 'Tag 2')

    within(first('.list-group-item')) do
      expect(page).to have_css('.facet-label', text: 'Tag 2')
      expect(page).to have_css('.facet-count', text: '1')
    end
    expect(page).to have_css('.list-group-item .facet-label', text: 'Tag 2 : Tag 2a')

    find('.list-group-item', text: 'Tag 2 : Tag 2a').click

    expect(page).to have_result_count(1)
    expect(page).to have_current_filter('Tags', 'Tag 2 : Tag 2a')
  end
end
