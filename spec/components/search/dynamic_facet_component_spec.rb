# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::DynamicFacetComponent, type: :component do
  let(:component) do
    described_class.new(facet_counts:, search_form:, form_field: :released_to_earthworks)
  end
  let(:search_form) { Search::ItemForm.new(released_to_earthworks: ['last_week'], page: 2) }
  let(:facet_counts) { instance_double(SearchResults::DynamicFacetCounts) }

  before do
    allow(facet_counts).to receive(:each)
      .and_yield(SearchResults::FacetCount.new(value: 'last_week', count: 5))
      .and_yield(SearchResults::FacetCount.new(value: 'last_month', count: 10))
    allow(facet_counts).to receive(:any?).and_return(true)
  end

  it 'renders the facet' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Released to Earthworks"] h3', text: 'Released to Earthworks')

    # Add a new facet value
    item = page.find('li', text: /Last month\s+\(10\)/)
    expect(item).to have_link('Last month',
                              href: '/search/items?released_to_earthworks%5B%5D=last_week&released_to_earthworks%5B%5D=last_month') # rubocop:disable Layout/LineLength

    # Remove an existing facet value
    collection_item = page.find('li', text: 'Last week')
    expect(collection_item).to have_link('Remove', href: '/search/items')
  end

  context 'when there are no facet counts' do
    before do
      allow(facet_counts).to receive(:any?).and_return(false)
    end

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
