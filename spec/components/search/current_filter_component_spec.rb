# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CurrentFilterComponent, type: :component do
  let(:component) { described_class.new(form_field:, value:, search_form:) }

  context 'when there are current filters' do
    let(:form_field) { :object_types }
    let(:value) { 'item' }
    let(:search_form) do
      Search::ItemForm.new(
        object_types: %w[item collection],
        projects: ['Project 1']
      )
    end

    it 'renders the current filter' do
      render_inline(component)

      expect(page).to have_css('li', text: /Object types:\s+item/)
      expect(page).to have_link('Remove',
                                href: '/search/items?object_types%5B%5D=collection&projects%5B%5D=Project+1',
                                title: 'Remove filter Object types: item')
    end
  end

  context 'when a filter for a dynamic facet' do
    let(:form_field) { :released_to_earthworks }
    let(:value) { 'last_year' }
    let(:search_form) do
      Search::ItemForm.new(
        released_to_earthworks: ['last_year']
      )
    end

    it 'renders the current filter' do
      render_inline(component)

      expect(page).to have_css('li', text: /Released to Earthworks:\s+Last year/)
    end
  end
end
