# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Facet paging', :solr do
  before do
    create(:solr_item, mimetypes: (1..15).map { |i| "application/test#{format('%02d', i)}" })
    sign_in(create(:user))
  end

  it 'returns facets' do
    visit search_path(query: 'test')

    find_facet_section('MIME types').click

    expect(page).to have_facet_value('application/test01', count: 1, facet: 'MIME types')
    expect(page).to have_facet_value('application/test10', count: 1, facet: 'MIME types')
    expect(page).not_to have_facet_value('application/test11', facet: 'MIME types', wait: 0)

    find_facet_more_link('MIME types').click
    expect(page).to have_facet_value('application/test11', count: 1, facet: 'MIME types')
    expect(page).to have_facet_value('application/test15', count: 1, facet: 'MIME types')

    expect(page).to have_no_link('More', wait: 0)
  end
end
