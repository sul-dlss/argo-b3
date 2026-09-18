# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetSearchResultComponent, type: :component do
  let(:component) { described_class.new(facet_count:) }
  let(:facet_count) do
    SearchResults::FacetCount.new(value: 'druid:bc123df4567', count: 10, label: 'My Collection')
  end

  it 'renders the facet search result' do
    render_inline(component)

    item = page.find('li.list-group-item[role="option"][data-autocomplete-value="druid:bc123df4567"]')
    expect(item).to have_css('.facet-label', text: 'My Collection')
    expect(item).to have_css('.facet-count', text: '10')
  end
end
