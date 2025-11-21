# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Hierarchical facet paging', :solr do
  before do
    create(:solr_item, projects: (1..30).map { |i| "project #{format('%02d', i)} : testing" })
  end

  it 'returns facets' do
    visit search_items_path(query: 'test')

    find_facet_section('Projects').click

    expect(page).to have_facet_value('project 01', count: 1, facet: 'Projects')
    expect(page).to have_facet_value('project 10', count: 1, facet: 'Projects')
    expect(page).not_to have_facet_value('project 26', facet: 'Projects', wait: 0)

    find_facet_more_link('Projects').click

    expect(page).to have_facet_value('project 26', count: 1, facet: 'Projects')
    expect(page).to have_facet_value('project 30', count: 1, facet: 'Projects')

    expect(page).to have_no_link('More', wait: 0)
  end
end
