# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::HierarchicalFacetComponent, type: :component do
  let(:component) do
    described_class.new(facet_counts:, search_form:, form_field:,
                        facet_children_path_helper:, facet_path_helper:, facet_search_path_helper:)
  end

  let(:facet_counts) { instance_double(SearchResults::HierarchicalFacetCounts, page: 1, to_ary: result_facet_counts, total_pages: 1) }

  let(:result_facet_counts) do
    [
      SearchResults::HierarchicalFacetCount.new(value: '2|SMPL : Audio|-', count: 10)
    ]
  end

  let(:search_form) { Search::ItemForm.new }
  let(:form_field) { :tags }
  let(:facet_path_helper) { Search::Facets::TAGS.facet_path_helper }
  let(:facet_children_path_helper) { Search::Facets::TAGS.facet_children_path_helper }
  let(:facet_search_path_helper) { nil }

  before do
    allow(facet_counts).to receive(:any?).and_return(result_facet_counts.any?)
  end

  it 'renders the hierarchical facet' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Tags"] h3', text: 'Tags')
    # There is a turbo-frame around the facet values
    expect(page).to have_css('turbo-frame#tags-facet-page1 ul')

    expect(page).to have_css('li', text: /Audio\s+\(10\)/)
  end

  context 'when facet search is enabled' do
    let(:facet_search_path_helper) { Search::Facets::TAGS.facet_search_path_helper }

    it 'renders the facet search input' do
      render_inline(component)

      expect(page).to have_field('Search these tags', type: 'text')
    end
  end

  context 'when paging is enabled' do
    let(:facet_page_path_helper) { Search::Facets::TAGS.facet_path_helper }

    before do
      allow(facet_counts).to receive(:total_pages).and_return(3)
    end

    it 'renders the next page link' do
      render_inline(component)

      turbo_frame = page.find('turbo-frame#tags-facet-page2')
      expect(turbo_frame).to have_link('More',
                                       href: '/search/tag_facets?facet_page=2')
    end
  end

  context 'when there are no facet counts' do
    let(:result_facet_counts) { [] }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
