# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FormHiddenFieldsComponent, type: :component do
  let(:component) { described_class.new(search_form:, form_field:, form_builder:) }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(nil, search_form, vc_test_controller.view_context, {}) }
  let(:search_form) { Search::ItemForm.new(object_types: %w[collection item], projects: ['Project 1'], page: 2, query: 'test', include_google_books: true) }

  context 'when rendering hidden fields for a facet field' do
    let(:form_field) { :object_types }

    it 'renders hidden fields for other search form attributes' do
      render_inline(component)

      expect(page).to have_field('projects[]', with: 'Project 1', type: 'hidden')
      expect(page).to have_no_field('page')
      expect(page).to have_field('query', with: 'test', type: 'hidden')
      expect(page).to have_field('include_google_books', with: 'true', type: 'hidden')
      expect(page).to have_no_field('object_types[]')
    end
  end

  context 'when rendering hidden fields not for a facet field' do
    let(:form_field) { nil }

    it 'renders hidden fields for other search form attributes' do
      render_inline(component)

      expect(page).to have_field('object_types[]', with: 'collection', type: 'hidden')
      expect(page).to have_field('object_types[]', with: 'item', type: 'hidden')
      expect(page).to have_field('projects[]', with: 'Project 1', type: 'hidden')
      expect(page).to have_no_field('page')
      expect(page).to have_no_field('query')
      expect(page).to have_no_field('include_google_books')
    end
  end
end
