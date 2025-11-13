# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetValueComponent, type: :component do
  let(:component) do
    described_class.new(count: 10, search_form:, form_field: :object_types,
                        value: 'collection', selected:, label:, data:)
  end
  let(:search_form) { Search::ItemForm.new(object_types: ['collection'], page: 2) }
  let(:label) { nil }
  let(:data) { {} }
  let(:selected) { true }

  context 'when selected' do
    it 'renders the selected facet value' do
      render_inline(component)

      expect(page).to have_content('collection')
      expect(page).to have_link('Remove', href: '/search/items')
    end
  end

  context 'when not selected' do
    let(:selected) { false }

    it 'renders the unselected facet value' do
      render_inline(component)

      expect(page).to have_link('collection',
                                href: '/search/items?object_types%5B%5D=collection')
      expect(page).to have_content('(10)')
      expect(page).to have_no_link('Remove')
    end
  end

  context 'when a label is provided' do
    let(:label) { 'Custom Label' }

    it 'uses the provided label' do
      render_inline(component)

      expect(page).to have_content('Custom Label')
    end
  end

  context 'when link arguments are provided' do
    let(:data) { { turbo: false } }

    it 'includes the link arguments in the link' do
      render_inline(component)

      expect(page).to have_link('Remove', href: '/search/items')
      expect(page).to have_css('a[data-turbo="false"]')
    end
  end
end
