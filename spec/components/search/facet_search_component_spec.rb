# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetSearchComponent, type: :component do
  let(:component) { described_class.new(search_form:, form_field: :tags, facet_search_path_helper:) }
  let(:search_form) { ResultsSearchForm.new(query: 'test', tags: ['test : tag']) }
  let(:facet_search_path_helper) { Search::FacetPathResolver.search_path_helper(facet_config: Search::Facets::TAGS, search_form:) }

  it 'renders the facet search input' do
    render_inline(component)

    expect(page).to have_css('div[data-controller="autocomplete form-submit"][data-autocomplete-url-value=' \
                             '"/search/tag_facets/search?query=test&tags%5B%5D=test+%3A+tag"]')
    expect(page).to have_field('Search tag', type: 'text')
    expect(page).to have_css('label[for="tags-facet-search"] .visually-hidden', text: 'Search tag')
    expect(page).to have_css("form[action='/search'][method='get']")
    expect(page).to have_field('query', with: 'test', type: 'hidden')
    expect(page).to have_field('tags[]', with: 'test : tag', type: 'hidden')
  end

  context 'when the search is advanced' do
    let(:search_form) { ResultsSearchForm.new(advanced: true, query: 'Miller OR octopus', tags: ['test : tag']) }

    it 'submits facet selections within the advanced search and retains the query and existing selections' do
      render_inline(component)

      within('form[action="/advanced_search?advanced=true"][method="get"]') do
        expect(page).to have_field('query', with: 'Miller OR octopus', type: 'hidden')
        expect(page).to have_field('tags[]', with: 'test : tag', type: 'hidden')
      end
    end
  end

  context 'when an advanced search is in the workflow status view' do
    let(:search_form) { WorkflowGridSearchForm.new(advanced: true, query: 'Miller OR octopus', tags: ['test : tag']) }

    it 'submits facet selections to the workflow view with the advanced query and existing selections' do
      render_inline(component)

      within('form[action="/workflow_grid"][method="get"]') do
        expect(page).to have_field('advanced', with: 'true', type: 'hidden')
        expect(page).to have_field('query', with: 'Miller OR octopus', type: 'hidden')
        expect(page).to have_field('tags[]', with: 'test : tag', type: 'hidden')
      end
    end
  end

  context 'when no facet_search_path_helper is provided' do
    let(:facet_search_path_helper) { nil }

    it 'does not render the facet search input' do
      expect(component.render?).to be false
    end
  end
end
