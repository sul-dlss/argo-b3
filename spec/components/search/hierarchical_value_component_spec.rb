# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::HierarchicalValueComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(facet_count:, search_form:, path_helper:, form_field:) }

  let(:search_form) { Search::ItemForm.new }
  let(:path_helper) do
    lambda { |parent_value:, **params|
      children_search_workflow_facets_path(parent_value:, **params)
    }
  end
  let(:form_field) { :wps_workflows }

  context 'when a leaf' do
    let(:facet_count) do
      instance_double(SearchResults::HierarchicalFacetCount,
                      branch?: false, value: 'ocrWF:end-ocr:waiting',
                      level: 3, count: 10, value_parts: %w[ocrWF end-ocr waiting])
    end

    context 'when not selected' do
      it 'renders without children and with a link' do
        render_inline(component)

        expect(page).to have_link('waiting', href: '/search/items?wps_workflows%5B%5D=ocrWF%3Aend-ocr%3Awaiting')
        expect(page).to have_content('(10)')
        expect(page).to have_no_css('a[data-bs-toggle="collapse"]')
        expect(page).to have_no_css('div.collapse')
      end
    end

    context 'when selected' do
      let(:search_form) do
        Search::ItemForm.new(wps_workflows: ['ocrWF:end-ocr:waiting'])
      end

      it 'renders without children and as selected' do
        render_inline(component)

        expect(page).to have_no_link('waiting', exact: true)
        expect(page).to have_content('waiting')
        expect(page).to have_link('Remove', href: '/search/items')
        expect(page).to have_no_css('a[data-bs-toggle="collapse"]')
        expect(page).to have_no_css('div.collapse')
      end
    end
  end

  context 'when a branch' do
    let(:facet_count) do
      instance_double(SearchResults::HierarchicalFacetCount,
                      branch?: true, value: 'ocrWF:end-ocr',
                      level: 2, count: 10, value_parts: %w[ocrWF end-ocr])
    end

    context 'when selected' do
      let(:search_form) do
        Search::ItemForm.new(wps_workflows: ['ocrWF:end-ocr'])
      end

      it 'renders with children showing and as selected' do
        render_inline(component)

        expect(page).to have_no_link('end-ocr', exact: true)
        expect(page).to have_content('end-ocr')
        expect(page).to have_link('Remove', href: '/search/items')
        expect(page).to have_link('+', href: '#collapse-ocrwf-end-ocr', title: 'Toggle end-ocr')
        expect(page).to have_css('div.collapse.show turbo-frame[src="/search/workflow_facets/children' \
                                 '?parent_value=ocrWF%3Aend-ocr&wps_workflows%5B%5D=ocrWF%3Aend-ocr"][loading="eager"]')
      end
    end

    context 'when not selected' do
      it 'renders with children and with a link' do
        render_inline(component)

        expect(page).to have_link('end-ocr', href: '/search/items?wps_workflows%5B%5D=ocrWF%3Aend-ocr')
        expect(page).to have_content('(10)')
        expect(page).to have_link('+', href: '#collapse-ocrwf-end-ocr')
        expect(page).to have_css('div.collapse:not(.show) turbo-frame[src="/search/workflow_facets/children' \
                                 '?parent_value=ocrWF%3Aend-ocr"][loading="lazy"]')
      end
    end

    context 'when a child is selected' do
      let(:search_form) do
        Search::ItemForm.new(wps_workflows: ['ocrWF:end-ocr:waiting'])
      end

      it 'renders with children showing and as not selected' do
        render_inline(component)

        expect(page).to have_link('end-ocr',
                                  href: '/search/items?wps_workflows%5B%5D=ocrWF%3Aend-ocr%3Awaiting' \
                                        '&wps_workflows%5B%5D=ocrWF%3Aend-ocr')
        expect(page).to have_content('(10)')
        expect(page).to have_link('+', href: '#collapse-ocrwf-end-ocr')
        expect(page).to have_css('div.collapse.show turbo-frame[src="/search/workflow_facets/children' \
                                 '?parent_value=ocrWF%3Aend-ocr&wps_workflows%5B%5D=ocrWF%3Aend-ocr%3Awaiting"]' \
                                 '[loading="eager"]')
      end
    end
  end
end
