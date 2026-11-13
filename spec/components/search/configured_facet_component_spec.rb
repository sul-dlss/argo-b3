# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ConfiguredFacetComponent, type: :component do
  let(:component) { described_class.new(facet_config:, facet_counts:, search_form:) }

  let(:search_form) { ResultsSearchForm.new }
  let(:facet_counts) { instance_double(SearchResults::FacetCounts, page: 1, total_pages: 2, any?: true) }

  before do
    allow(facet_counts).to receive(:each).and_yield(facet_count)
    allow(facet_counts).to receive(:to_ary).and_return([facet_count])
  end

  context 'with an :or facet' do
    let(:facet_config) { Search::Facets::OBJECT_TYPES }
    let(:facet_count) { SearchResults::FacetCount.new(value: 'item', count: 10) }

    it 'renders a checkbox facet' do
      render_inline(component)

      expect(page).to have_css('section[aria-label="Object type"]')
      expect(page).to have_field('item', type: 'checkbox')
    end
  end

  context 'with a dynamic facet with a date range' do
    let(:facet_config) { Search::Facets::REGISTERED_DATE }
    let(:facet_counts) { instance_double(SearchResults::DynamicFacetCounts, any?: true) }
    let(:facet_count) { SearchResults::FacetCount.new(value: 'today', count: 5) }

    it 'renders a dynamic facet with date range inputs' do
      render_inline(component)

      expect(page).to have_link('Today')
      expect(page).to have_field('From', type: 'date')
    end
  end

  context 'with a dynamic facet without a date range' do
    let(:facet_config) { Search::Facets::IDENTIFIERS }
    let(:facet_counts) { instance_double(SearchResults::DynamicFacetCounts, any?: true) }
    let(:facet_count) { SearchResults::FacetCount.new(value: 'has_doi', count: 5) }

    it 'renders a dynamic facet without date range inputs' do
      render_inline(component)

      expect(page).to have_link('Has DOI')
      expect(page).to have_no_field('From')
    end
  end

  context 'with a hierarchical facet' do
    let(:facet_config) { Search::Facets::TAGS }
    let(:facet_counts) { instance_double(SearchResults::HierarchicalFacetCounts, page: 1, total_pages: 2, any?: true) }
    let(:facet_count) { SearchResults::HierarchicalFacetCount.new(value: '2|SMPL : Audio|-', count: 10) }

    it 'renders a hierarchical facet with paging and search' do
      render_inline(component)

      expect(page).to have_css('ul[data-controller="hierarchical-facet-value"] li', text: 'Audio')
      expect(page).to have_link('More Tag', href: '/search/tag_facets?facet_page=2')
      expect(page).to have_field('Search tag', type: 'text')
    end
  end

  context 'with a basic facet with excludes' do
    let(:facet_config) { Search::Facets::ACCESS_RIGHTS }
    let(:facet_count) { SearchResults::FacetCount.new(value: 'dark', count: 10) }

    it 'renders a facet with exclude links' do
      render_inline(component)

      expect(page).to have_link('dark', href: '/search?access_rights%5B%5D=dark')
      expect(page).to have_link(href: '/search?access_rights_exclude%5B%5D=dark')
    end
  end

  context 'with a basic facet with paging and search' do
    let(:facet_config) { Search::Facets::MIMETYPES }
    let(:facet_count) { SearchResults::FacetCount.new(value: 'application/pdf', count: 10) }

    it 'renders a facet with paging and search' do
      render_inline(component)

      expect(page).to have_link('application/pdf')
      expect(page).to have_link('More MIME type', href: '/search/mimetype_facets?facet_page=2')
      expect(page).to have_field('Search mime type', type: 'text')
    end
  end
end
