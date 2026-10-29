# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FormHiddenFieldsComponent, type: :component do
  let(:component) { described_class.new(search_form:, form_field:, form_builder:) }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(nil, search_form, vc_test_controller.view_context, {}) }
  let(:search_form) do
    ResultsSearchForm.new(object_types: %w[collection item],
                          projects: ['Project 1'],
                          page: 2,
                          query: 'test')
  end
  let(:form_field) { :object_types }

  context 'when rendering hidden fields for a facet field' do
    it 'renders hidden fields for other search form attributes' do
      render_inline(component)

      expect(page).to have_field('projects[]', with: 'Project 1', type: 'hidden')
      expect(page).to have_no_field('page', type: 'hidden')
      expect(page).to have_field('query', with: 'test', type: 'hidden')
      expect(page).to have_no_field('object_types[]', type: 'hidden')
    end

    it 'renders hidden fields without ids (which would duplicate the ids of inputs elsewhere on the page)' do
      render_inline(component)

      expect(page).to have_css('input[type="hidden"]', visible: :all, count: 2)
      expect(page).to have_no_css('input[type="hidden"][id]', visible: :all)
    end
  end

  context 'when rendering hidden fields not for a facet field' do
    let(:form_field) { nil }

    it 'renders hidden fields for other search form attributes' do
      render_inline(component)

      expect(page).to have_field('object_types[]', with: 'collection', type: 'hidden')
      expect(page).to have_field('object_types[]', with: 'item', type: 'hidden')
      expect(page).to have_field('projects[]', with: 'Project 1', type: 'hidden')
      expect(page).to have_no_field('page', type: 'hidden')
      expect(page).to have_field('query', with: 'test', type: 'hidden')
    end
  end

  context 'when rendering hidden fields for multiple fields' do
    let(:form_field) { %i[object_types projects] }

    it 'renders hidden fields for the other search form attributes' do
      render_inline(component)

      expect(page).to have_no_field('object_types[]', type: 'hidden')
      expect(page).to have_no_field('projects[]', type: 'hidden')
      expect(page).to have_field('query', with: 'test', type: 'hidden')
    end
  end

  context 'when rendering hidden fields for scalar attributes' do
    let(:search_form) { ResultsSearchForm.new(dates: %w[2001 2002], dates_from: '1999') }
    let(:form_field) { nil }

    it 'renders scalar hidden fields for scalar attributes and array hidden fields for array attributes' do
      render_inline(component)

      expect(page).to have_field('dates_from', with: '1999', type: 'hidden')
      expect(page).to have_no_field('dates_from[]', type: 'hidden')
      expect(page).to have_field('dates[]', with: '2001', type: 'hidden')
      expect(page).to have_field('dates[]', with: '2002', type: 'hidden')
    end
  end

  context 'when excluding query' do
    let(:form_field) { :query }

    it 'does not render hidden field' do
      render_inline(component)

      expect(page).to have_no_field('query', type: 'hidden')
    end
  end
end
