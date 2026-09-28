# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetsSectionComponent, type: :component do
  let(:component) { described_class.new(search_form:) }

  context 'with a blank search form' do
    let(:search_form) { ResultsSearchForm.new }

    it 'renders containers for all facets' do
      render_inline(component)

      # Facets that will be populated by turbo streams in search results.
      expect(page).to have_css('div#object-types-facet', text: 'Loading')

      # Lazy facets.
      expect(page).to have_css('turbo-frame#projects-facet[src="/search/project_facets"]', text: 'Loading')
      expect(page).to have_css('turbo-frame#tags-facet[src="/search/tag_facets"]', text: 'Loading')
      expect(page).to have_css('turbo-frame#tickets-facet[src="/search/ticket_facets"]', text: 'Loading')
    end
  end

  context 'with a populated search form' do
    let(:search_form) { ResultsSearchForm.new(query: 'test') }

    it 'renders containers for all facets' do
      render_inline(component)

      # Facets that will be populated by turbo streams in search results.
      expect(page).to have_css('div#object-types-facet', text: 'Loading')

      # Lazy facets.
      expect(page)
        .to have_css('turbo-frame#projects-facet[src="/search/project_facets?query=test"]',
                     text: 'Loading')
    end
  end
end
