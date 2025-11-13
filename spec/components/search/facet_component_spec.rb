# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetComponent, type: :component do
  let(:component) do
    described_class.new(facet_counts:, search_form:, form_field: :object_types)
  end
  let(:search_form) { Search::ItemForm.new(object_types: ['collection'], page: 2) }
  let(:facet_counts) do
    [
      SearchResults::FacetCount.new(value: 'collection', count: 10),
      SearchResults::FacetCount.new(value: 'item', count: 5)
    ]
  end

  it 'renders the facet' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Object types"] h3', text: 'Object types')
    # Add a new facet value
    item = page.find('li', text: /item\s+\(5\)/)
    expect(item).to have_link('item',
                              href: '/search/items?object_types%5B%5D=collection&object_types%5B%5D=item')

    # Remove an existing facet value
    collection_item = page.find('li', text: 'collection')
    expect(collection_item).to have_link('Remove', href: '/search/items')
  end

  context 'when there are no facet counts' do
    let(:facet_counts) { [] }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
