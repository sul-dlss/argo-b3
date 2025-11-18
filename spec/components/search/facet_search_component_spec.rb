# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetSearchComponent, type: :component do
  let(:component) { described_class.new(path:, search_form:, form_field: :tags) }
  let(:search_form) { Search::ItemForm.new(query: 'test', tags: ['test : tag']) }
  let(:path) { '/some/autocomplete-path' }

  it 'renders the facet search input' do
    render_inline(component)

    expect(page).to have_css('div[data-controller="autocomplete facet-search"][data-autocomplete-url-value="/some/autocomplete-path"]') # rubocop:disable Layout/LineLength
    expect(page).to have_field('Search these tags', type: 'text')
    expect(page).to have_css("form[action='/search/items'][method='get']")
    expect(page).to have_field('search[query]', with: 'test', type: 'hidden')
    expect(page).to have_field('search[tags][]', with: 'test : tag', type: 'hidden')
  end
end
