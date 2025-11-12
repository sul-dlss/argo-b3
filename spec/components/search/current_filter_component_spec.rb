# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CurrentFilterComponent, type: :component do
  let(:component) { described_class.new(form_field: 'object_types', value: 'item', search_form:) }

  context 'when there are current filters' do
    let(:search_form) do
      Search::ItemForm.new(
        object_types: %w[item collection],
        projects: ['Project 1']
      )
    end

    it 'renders the current filter' do
      render_inline(component)

      expect(page).to have_css('li', text: 'Object types: item')
      expect(page).to have_link('Remove',
                                href: '/search/items?object_types%5B%5D=collection&projects%5B%5D=Project+1',
                                title: 'Remove filter Object types: item')
    end
  end
end
