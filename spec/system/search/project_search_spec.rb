# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project search', :solr do
  before do
    create_list(:solr_item, 5, :with_projects)
  end

  it 'returns project tag search results' do
    visit root_path

    assert_home_page

    find_search_field.fill_in(with: '2a')
    click_button('Search')

    within(find_project_results_section) do
      expect(page).to have_result_count(1)
      find_project_result('Project 2 : Project 2a').first('a').click
    end

    assert_item_search_page

    within(find_item_results_section) do
      expect(page).to have_result_count(5)
    end

    expect(page).to have_selected_facet_value('Project 2a', facet: 'Projects')
  end
end
