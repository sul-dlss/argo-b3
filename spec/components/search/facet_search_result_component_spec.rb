# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetSearchResultComponent, type: :component do
  let(:component) { described_class.new(facet_count:) }
  let(:facet_count) { SearchResults::FacetCount.new(value: 'collection', count: 10) }

  it 'renders the facet search result' do
    render_inline(component)

    expect(page).to have_css('li.list-group-item[role="option"][data-autocomplete-value="collection"]',
                             text: 'collection (10)')
  end
end
