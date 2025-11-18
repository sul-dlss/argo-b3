# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetsSectionComponent, type: :component do
  let(:component) { described_class.new(search_form:) }

  context 'with a blank search form' do
    let(:search_form) { Search::Form.new }

    it 'renders containers for facets' do
      render_inline(component)

      # Facets that will be populated by turbo streams in search results.
      expect(page).to have_css('div#object-types-facet', text: 'Loading')

      # Does not render facets that are omitted for blank searches.
      expect(page).to have_no_css('#project-tags-facet')
    end
  end

  context 'with a populated search form' do
    let(:search_form) { Search::Form.new(query: 'test') }

    it 'renders containers for all facets' do
      render_inline(component)

      # Facets that will be populated by turbo streams in search results.
      expect(page).to have_css('div#object-types-facet', text: 'Loading')

      # Lazy facets.
      expect(page)
        .to have_css('turbo-frame#projects-facet[src="/search/project_facets?page=1&query=test"]',
                     text: 'Loading')
    end
  end
end
