# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SortComponent, type: :component do
  let(:component) { described_class.new(search_form:) }

  context 'when sort is not set' do
    let(:search_form) { SearchForm.new }

    it 'renders the default component' do
      render_inline(component)

      expect(page).to have_button('Sort by Relevance')
      expect(page).to have_link('Relevance', href: '/search/items?sort=relevance')
      expect(page).to have_link('Druid', href: '/search/items?sort=druid')
    end
  end

  context 'when sort is set' do
    let(:search_form) { SearchForm.new(sort: 'druid') }

    it 'renders the component with the specified sort' do
      render_inline(component)

      expect(page).to have_button('Sort by Druid')
      expect(page).to have_link('Relevance', href: '/search/items?sort=relevance')
      expect(page).to have_link('Druid', href: '/search/items?sort=druid')
    end
  end
end
