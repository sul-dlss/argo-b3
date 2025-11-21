# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Facet paging', :solr do
  before do
    create(:solr_item, mimetypes: (1..15).map { |i| "application/test#{format('%02d', i)}" })
  end

  it 'returns facets' do
    visit search_items_path(query: 'test')

    find_facet_section('MIME Types').click

    expect(page).to have_facet_value('application/test01', count: 1, facet: 'MIME Types')
    expect(page).to have_facet_value('application/test10', count: 1, facet: 'MIME Types')
    expect(page).not_to have_facet_value('application/test11', facet: 'MIME Types', wait: 0)

    find_facet_more_link('MIME Types').click

    expect(page).to have_facet_value('application/test11', count: 1, facet: 'MIME Types')
    expect(page).to have_facet_value('application/test15', count: 1, facet: 'MIME Types')

    expect(page).to have_no_link('More', wait: 0)
  end
end
