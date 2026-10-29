# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FormHiddenFieldsComponent, type: :component do
  let(:component) { described_class.new(search_form:, form_fields:, form_builder:) }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(nil, search_form, vc_test_controller.view_context, {}) }
  let(:search_form) do
    ResultsSearchForm.new(object_types: %w[collection item],
                          projects: ['Project 1'],
                          page: 2,
                          query: 'test')
  end
  let(:form_fields) { :object_types }

  context 'when rendering hidden fields for a facet field' do
    it 'renders hidden fields for other search form attributes' do
      render_inline(component)

      expect(page).to have_field('projects[]', with: 'Project 1', type: 'hidden')
      expect(page).to have_no_field('page', type: 'hidden')
      expect(page).to have_field('query', with: 'test', type: 'hidden')
      expect(page).to have_no_field('object_types[]', type: 'hidden')
    end
  end

  context 'when rendering hidden fields not for a facet field' do
    let(:form_fields) { nil }

    it 'renders hidden fields for other search form attributes' do
      render_inline(component)

      expect(page).to have_field('object_types[]', with: 'collection', type: 'hidden')
      expect(page).to have_field('object_types[]', with: 'item', type: 'hidden')
      expect(page).to have_field('projects[]', with: 'Project 1', type: 'hidden')
      expect(page).to have_no_field('page', type: 'hidden')
      expect(page).to have_field('query', with: 'test', type: 'hidden')
    end
  end

  context 'when rendering hidden fields for a date range' do
    let(:search_form) { ResultsSearchForm.new(registered_date_from: '2024-01-01', content_types: ['image']) }
    let(:form_fields) { :content_types }

    it 'renders a single-valued hidden field' do
      render_inline(component)

      expect(page).to have_field('registered_date_from', with: '2024-01-01', type: 'hidden')
      expect(page).to have_no_field('registered_date_from[]', type: 'hidden')
    end
  end

  context 'when rendering hidden fields for a date range facet' do
    let(:search_form) do
      ResultsSearchForm.new(registered_date_from: '2024-01-01', registered_date_to: '2024-12-31',
                            content_types: ['image'])
    end
    let(:form_fields) { %i[registered_date registered_date_from registered_date_to] }

    it 'does not render hidden fields for the excluded fields' do
      render_inline(component)

      expect(page).to have_no_field('registered_date_from', type: 'hidden')
      expect(page).to have_no_field('registered_date_to', type: 'hidden')
      expect(page).to have_field('content_types[]', with: 'image', type: 'hidden')
    end
  end

  context 'when excluding query' do
    let(:form_fields) { :query }

    it 'does not render hidden field' do
      render_inline(component)

      expect(page).to have_no_field('query', type: 'hidden')
    end
  end
end
