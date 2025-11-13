# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show home page', :solr do
  before do
    create_list(:solr_item, 4)
    create_list(:solr_collection, 3)
  end

  it 'displays the home page' do
    visit root_path

    expect(page).to have_css('h1', text: 'Home Page')

    # Shows home page facets
    expect(page).to have_facet('Object Types', expanded: false)
    find_facet_section('Object Types').click
    expect(page).to have_facet_value('item', facet: 'Object Types', count: 4)
    expect(page).to have_facet_value('collection', facet: 'Object Types', count: 3)

    # Does not show non-home page facets
    expect(page).not_to have_facet('Project Tags', wait: 0)
  end
end
