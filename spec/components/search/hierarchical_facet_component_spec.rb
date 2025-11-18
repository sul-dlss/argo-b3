# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::HierarchicalFacetComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(facet_counts:, search_form:, form_field:, path_helper:) }

  let(:facet_counts) do
    [
      SearchResults::HierarchicalFacetCount.new(value: '2|SMPL : Audio|-', count: 10)
    ]
  end

  let(:search_form) { Search::ItemForm.new }
  let(:form_field) { :tags }
  let(:path_helper) do
    lambda { |parent_value:, **params|
      tags_children_search_facets_path(parent_value:, **params)
    }
  end

  it 'renders the hierarchical facet' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Tags"] h3', text: 'Tags')
    expect(page).to have_css('li', text: /Audio\s+\(10\)/)
  end

  context 'when facet search is enabled' do
    let(:component) do
      described_class.new(facet_counts:, search_form:, form_field:, path_helper:).tap do |component|
        component.with_facet_search(path:)
      end
    end

    let(:path) { '/some/autocomplete-path' }

    it 'renders the facet search input' do
      render_inline(component)

      expect(page).to have_field('Search these tags', type: 'text')
    end
  end

  context 'when there are no facet counts' do
    let(:facet_counts) { [] }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
