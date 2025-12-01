# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tag search', :solr do
  before do
    create_list(:solr_item, 5, :with_tags)
  end

  it 'returns tag search results' do
    visit root_path

    assert_home_page

    find_search_field.fill_in(with: '2a')
    click_button('Search')

    within(find_tag_results_section) do
      expect(page).to have_result_count(1)
      find_tag_result('Tag 2 : Tag 2a').first('a').click
    end

    assert_item_search_page

    within(find_item_results_section) do
      expect(page).to have_result_count(5)
    end

    expect(page).to have_selected_facet_value('Tag 2a', facet: 'Tags')
  end
end
