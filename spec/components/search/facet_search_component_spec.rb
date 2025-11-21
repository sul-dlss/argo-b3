# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetSearchComponent, type: :component do
  let(:component) { described_class.new(search_form:, form_field: :tags, facet_search_path_helper:) }
  let(:search_form) { Search::ItemForm.new(query: 'test', tags: ['test : tag']) }
  let(:facet_search_path_helper) { Search::Facets::TAGS.facet_search_path_helper }

  it 'renders the facet search input' do
    render_inline(component)

    expect(page).to have_css('div[data-controller="autocomplete facet-search"][data-autocomplete-url-value=' \
                             '"/search/tag_facets/search?query=test&tags%5B%5D=test+%3A+tag"]')
    expect(page).to have_field('Search these tags', type: 'text')
    expect(page).to have_css("form[action='/search/items'][method='get']")
    expect(page).to have_field('search[query]', with: 'test', type: 'hidden')
    expect(page).to have_field('search[tags][]', with: 'test : tag', type: 'hidden')
  end

  context 'when no facet_search_path_helper is provided' do
    let(:facet_search_path_helper) { nil }

    it 'does not render the facet search input' do
      expect(component.render?).to be false
    end
  end
end
