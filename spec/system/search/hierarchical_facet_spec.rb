# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Hierarchical facets', :solr do
  before do
    create(:solr_item, :with_projects)
    create(:solr_collection, :with_projects, projects: ['Project 1'])
  end

  it 'returns facets' do
    visit search_items_path(query: 'test')

    expect(page).to have_css('h1', text: 'Items search page')

    expect(page).to have_result_count(2)

    find_facet_section('Projects').click
    expect(page).to have_facet_value('Project 1', count: 2, facet: 'Projects')
    expect(page).to have_facet_value('Project 2', count: 1, facet: 'Projects')

    within(find_facet_section('Projects')) do
      click_link('Project 1')
    end

    expect(page).to have_result_count(2)
    expect(page).to have_current_filter('Projects', 'Project 1')

    within(find_facet_section('Projects')) do
      click_link('Remove', title: 'Remove Project 1')
    end

    expect(page).to have_result_count(2)
    expect(page).not_to have_current_filter('Projects', 'Project 1', wait: 0)

    find_facet_section('Projects').click
    within(find_facet_section('Projects')) do
      click_link('Project 2')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_current_filter('Projects', 'Project 2')

    expect(page).to have_facet_value('Project 1', count: 1, facet: 'Projects')
    expect(page).to have_facet_value('Project 2a', count: 1, facet: 'Projects')

    within(find_facet_section('Projects')) do
      expect(page).to have_text('Project 2')
      expect(page).to have_no_link('Project 2', exact: true)
      click_link('Remove')
    end

    expect(page).to have_result_count(2)
    expect(page).not_to have_current_filter('Projects', 'Project 2', wait: 0)

    find_facet_section('Projects').click
    find_facet_toggle('Project 2', facet_label: 'Projects').click
    expect(page).to have_facet_value('Project 2a', count: 1, facet: 'Projects')

    within(find_facet_section('Projects')) do
      click_link('Project 2a')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_current_filter('Projects', 'Project 2 : Project 2a')

    within(find_facet_section('Projects')) do
      expect(page).to have_text('Project 2a')
      expect(page).to have_no_link('Project 2a', exact: true)
      click_link('Remove', title: 'Remove Project 2a')
    end

    expect(page).to have_result_count(2)
    expect(page).not_to have_current_filter('Projects', 'Project 2 : Project 2a', wait: 0)
  end
end
