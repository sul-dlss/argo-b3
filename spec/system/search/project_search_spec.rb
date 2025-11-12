# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project search', :solr do
  before do
    create_list(:solr_item, 5, :with_projects)
  end

  it 'returns project tag search results' do
    visit root_path

    expect(page).to have_css('h1', text: 'Home Page')

    fill_in('Search for items, tags or projects', with: 'Project 1')
    click_button('Search')

    within(find_project_results_section) do
      expect(page).to have_result_count(1)
      find_project_result('Project 1').first('a').click
    end

    expect(page).to have_css('h1', text: 'Items search page')

    within(find_item_results_section) do
      expect(page).to have_result_count(5)
    end

    expect(page).to have_selected_facet_value('Project 1', facet: 'Projects')
  end
end
