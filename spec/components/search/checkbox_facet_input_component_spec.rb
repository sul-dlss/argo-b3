# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CheckboxFacetInputComponent, type: :component do
  let(:component) { described_class.new(search_form:, form_field:, form_builder:, facet_count:) }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(nil, search_form, vc_test_controller.view_context, {}) }
  let(:form_field) { :object_types }
  let(:facet_count) { SearchResults::FacetCount.new(value: 'collection', count: 10) }

  context 'when the facet value is selected' do
    let(:search_form) { Search::ItemForm.new(object_types: ['collection']) }

    it 'renders the checkbox as checked' do
      render_inline(component)

      expect(page).to have_field('collection (10)', type: 'checkbox', checked: true)
    end
  end

  context 'when the facet value is not selected' do
    let(:search_form) { Search::ItemForm.new(object_types: ['item']) }

    it 'renders the checkbox as unchecked' do
      render_inline(component)

      expect(page).to have_field('collection (10)', type: 'checkbox', checked: false)
    end
  end
end
