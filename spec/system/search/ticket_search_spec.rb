# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project search', :solr do
  let!(:solr_item) { create(:solr_item, ticket: 'TESTREQ-0') }

  before do
    Search::Facets::TICKETS.limit = 5
    create_list(:solr_item, 6)
    create(:solr_item, ticket: 'TESTREQ-Z9')
  end

  it 'returns ticket search results' do
    visit root_path

    assert_home_page

    find_search_field.fill_in(with: 'TESTREQ-0')
    click_button('Search')

    within(find_ticket_results_section) do
      expect(page).to have_result_count(1)
      find_ticket_result('TESTREQ-0').first('a').click
    end

    assert_item_search_page

    within(find_item_results_section) do
      expect(page).to have_result_count(1)
      expect(page).to have_item_result(solr_item)
    end

    expect(page).to have_selected_facet_value('TESTREQ-0', facet: 'Tickets')

    find_current_filter('Tickets', 'TESTREQ-0').click_link('Remove')

    find_search_field.fill_in(with: 'test')
    click_button('Search')

    find_facet_section('Tickets').click
    expect(page).to have_facet_value('TESTREQ-0', count: 1, facet: 'Tickets')
    expect(page).not_to have_facet_value('TESTREQ-Z9', count: 1, facet: 'Tickets', wait: 0)

    find_facet_more_link('Tickets').click

    expect(page).to have_facet_value('TESTREQ-Z9', count: 1, facet: 'Tickets')
  end
end
