# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetComponent, type: :component do
  let(:component) do
    described_class.new(facet_counts:, search_form:, form_field: :object_types,
                        facet_page_path_helper:, facet_search_path_helper:)
  end
  let(:search_form) { SearchForm.new(object_types: ['collection'], page: 2) }
  let(:facet_counts) { instance_double(SearchResults::FacetCounts, page: 1) }
  let(:facet_page_path_helper) { nil }
  let(:facet_search_path_helper) { nil }

  before do
    allow(facet_counts).to receive(:each)
      .and_yield(SearchResults::FacetCount.new(value: 'collection', count: 10))
      .and_yield(SearchResults::FacetCount.new(value: 'item', count: 5))
    allow(facet_counts).to receive(:any?).and_return(true)
  end

  it 'renders the facet' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Object types"] h3 button[aria-expanded="true"]', text: 'Object types')
    # There is a turbo-frame around the facet values
    expect(page).to have_css('turbo-frame#object-types-facet-page1 ul')

    # Add a new facet value
    item = page.find('li', text: 'item')
    expect(item).to have_link('item',
                              href: '/search?object_types%5B%5D=collection&object_types%5B%5D=item')

    # Remove an existing facet value
    collection_item = page.find('li', text: 'collection')
    expect(collection_item).to have_link('Remove collection', href: '/search')
  end

  context 'when paging is enabled' do
    # Object types doesn't have facet_path_helper, so borrowing from projects facet for test.
    let(:facet_page_path_helper) { Search::Facets::PROJECTS.facet_path_helper }

    before do
      allow(facet_counts).to receive(:total_pages).and_return(3)
    end

    it 'renders the next page link' do
      render_inline(component)

      turbo_frame = page.find('turbo-frame#object-types-facet-page2')
      expect(turbo_frame).to have_link('More',
                                       href: '/search/project_facets?facet_page=2&object_types%5B%5D=collection')
    end
  end

  context 'when facet search is enabled' do
    let(:facet_search_path_helper) { Search::Facets::PROJECTS.facet_search_path_helper }

    it 'renders the facet search input' do
      render_inline(component)

      expect(page).to have_field('Search these object types', type: 'text')
    end
  end

  context 'when there are no facet counts' do
    before do
      allow(facet_counts).to receive(:any?).and_return(false)
    end

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end

  context 'when a facet with exclude_form_field' do
    let(:component) do
      described_class.new(facet_counts:, search_form:, form_field: :access_rights,
                          exclude_form_field: :access_rights_exclude,
                          facet_page_path_helper:, facet_search_path_helper:)
    end
    let(:search_form) { SearchForm.new(access_rights_exclude: ['dark'], page: 2) }

    before do
      allow(facet_counts).to receive(:each)
        .and_yield(SearchResults::FacetCount.new(value: 'world', count: 8))
        .and_yield(SearchResults::FacetCount.new(value: 'dark', count: 3))
      allow(facet_counts).to receive(:any?).and_return(true)
    end

    it 'renders the facet with exclude selected' do
      render_inline(component)

      expect(page)
        .to have_css('section[aria-label="Access rights"] h3 button[aria-expanded="true"]', text: 'Access rights')

      # Add a new facet value
      item = page.find('li', text: 'world')
      expect(item).to have_link('Exclude world',
                                href: '/search?access_rights_exclude%5B%5D=dark&access_rights_exclude%5B%5D=world')

      # Remove an existing facet value
      collection_item = page.find('li', text: 'dark exclude')
      expect(collection_item).to have_link('Remove dark exclude', href: '/search')
    end
  end
end
