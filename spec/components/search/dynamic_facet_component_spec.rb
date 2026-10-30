# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::DynamicFacetComponent, type: :component do
  let(:component) do
    described_class.new(facet_counts:, search_form:, form_field: :released_to_earthworks)
  end
  let(:search_form) { ResultsSearchForm.new(released_to_earthworks: ['today'], page: 2) }
  let(:facet_counts) { instance_double(SearchResults::DynamicFacetCounts) }

  before do
    allow(facet_counts).to receive(:each)
      .and_yield(SearchResults::FacetCount.new(value: 'today', count: 5))
      .and_yield(SearchResults::FacetCount.new(value: 'last_7_days', count: 10))
    allow(facet_counts).to receive(:any?).and_return(true)
  end

  it 'renders the facet' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Released to EarthWorks"] h3', text: 'Released to EarthWorks')

    # Add a new facet value
    item = page.find('li', text: 'Last 7 days')
    expect(item).to have_link('Last 7 days',
                              href: '/search?released_to_earthworks%5B%5D=today&released_to_earthworks%5B%5D=last_7_days') # rubocop:disable Layout/LineLength

    # Remove an existing facet value
    collection_item = page.find('li', text: 'Today')
    expect(collection_item).to have_link('Remove', href: '/search')
  end

  context 'when there are no facet counts' do
    before do
      allow(facet_counts).to receive(:any?).and_return(false)
    end

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end

  context 'when date range form fields are provided' do
    let(:component) do
      described_class.new(facet_counts:, search_form:, form_field: :earliest_accessioned_date,
                          date_from_form_field: :earliest_accessioned_date_from,
                          date_to_form_field: :earliest_accessioned_date_to)
    end
    let(:search_form) { ResultsSearchForm.new(earliest_accessioned_date: ['today'], page: 2) }

    it 'renders the date range inputs' do
      render_inline(component)

      expect(page).to have_css('section[aria-label="First deposited date"]')

      expect(page).to have_field('From', type: 'date')
      expect(page).to have_field('To', type: 'date')
    end
  end
end
