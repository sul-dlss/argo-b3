# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show search page', :solr do
  before do
    create_list(:solr_item, 4)
    create_list(:solr_collection, 3)
    sign_in(create(:user, :reader))
  end

  it 'displays the search page' do
    visit search_path

    # Shows home page facets
    expect(page).to have_facet('Object type', expanded: false)
    find_facet_section('Object type').click
    expect(page).to have_facet_value('item', facet: 'Object type', count: 4)
    expect(page).to have_facet_value('collection', facet: 'Object type', count: 3)

    # Does not show non-home page facets
    expect(page).not_to have_facet('Project Tags', wait: 0)
  end
end
