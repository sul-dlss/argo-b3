# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetSearchResultComponent, type: :component do
  let(:component) { described_class.new(facet_count:) }
  let(:facet_count) { SearchResults::FacetCount.new(value: 'collection', count: 10) }

  it 'renders the facet search result' do
    render_inline(component)

    item = page.find('li.list-group-item[role="option"][data-autocomplete-value="collection"]')
    expect(item).to have_css('.facet-label', text: 'collection')
    expect(item).to have_css('.facet-count', text: '10')
  end

  context 'when the facet count has a composite value/label (e.g. druid/title)' do
    let(:facet_count) { SearchResults::FacetCount.new(value: 'druid:bc123df4567', label: 'University Archives', count: 10) }

    it 'renders the label but keys the autocomplete value on the druid' do
      render_inline(component)

      item = page.find('li.list-group-item[role="option"][data-autocomplete-value="druid:bc123df4567"]')
      expect(item).to have_css('.facet-label', text: 'University Archives')
    end
  end
end
