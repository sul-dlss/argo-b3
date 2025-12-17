# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Date range dynamic facets', :solr do
  let!(:year_ago_item_doc) { create(:solr_item) }
  let!(:now_item_doc) { create(:solr_item, earliest_accessioned_date: Time.zone.now) }

  let(:from) { 2.years.ago }
  let(:to) { 6.months.ago }

  before do
    sign_in(create(:user))
  end

  it 'returns facets' do
    visit search_path(query: 'test')

    expect(page).to have_result_count(2)

    # Earliest accessioned is a dynamic facet.
    find_facet_section('Earliest accessioned').click
    expect(page).to have_facet_value('Last day', count: 1, facet: 'Earliest accessioned')
    expect(page).to have_facet_value('Last week', count: 1, facet: 'Earliest accessioned')
    expect(page).to have_facet_value('Last month', count: 1, facet: 'Earliest accessioned')
    expect(page).to have_facet_value('Last year', count: 2, facet: 'Earliest accessioned')
    expect(page).to have_facet_value('All', count: 2, facet: 'Earliest accessioned')

    within(find_facet_section('Earliest accessioned')) do
      fill_in 'From', with: from.strftime('%m-%d-%Y')
      fill_in 'To', with: to.strftime('%m-%d-%Y')
      click_button 'Filter'
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(year_ago_item_doc)
    expect(page).not_to have_item_result(now_item_doc, wait: 0)

    expect(page).to have_current_filter('Earliest accessioned from', from.strftime('%Y-%m-%d'))
    expect(page).to have_current_filter('Earliest accessioned to', to.strftime('%Y-%m-%d'))
    expect(page).to have_facet('Earliest accessioned', expanded: true)

    find_current_filter('Earliest accessioned from', from.strftime('%Y-%m-%d')).click
    within(find_current_filters_section) do
      click_link('Remove Earliest accessioned to')
    end
    expect(page).to have_result_count(2)
  end
end
