# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SortComponent, type: :component do
  let(:component) { described_class.new(search_form:) }

  context 'when sort is not set' do
    let(:search_form) { ResultsSearchForm.new }

    it 'renders the default component' do
      render_inline(component)

      expect(page).to have_button('Sort by Relevance')
      expect(page.all('.dropdown-menu a').map(&:text)).to eq(['Relevance',
                                                              'Last deposited date (ascending)',
                                                              'Last deposited date (descending)',
                                                              'Registered date (ascending)',
                                                              'Registered date (descending)',
                                                              'Source ID',
                                                              'Druid'])
      expect(page).to have_link('Relevance', href: '/search/items?sort=relevance')
      expect(page).to have_link('Last deposited date (ascending)',
                                href: '/search/items?sort=last_deposited_date_asc')
      expect(page).to have_link('Last deposited date (descending)',
                                href: '/search/items?sort=last_deposited_date_desc')
      expect(page).to have_link('Registered date (ascending)', href: '/search/items?sort=registered_date_asc')
      expect(page).to have_link('Registered date (descending)', href: '/search/items?sort=registered_date_desc')
      expect(page).to have_link('Source ID', href: '/search/items?sort=source_id')
      expect(page).to have_link('Druid', href: '/search/items?sort=druid')
    end
  end

  context 'when sort is set' do
    let(:search_form) { ResultsSearchForm.new(sort: 'registered_date_desc') }

    it 'renders the component with the specified sort' do
      render_inline(component)

      expect(page).to have_button('Sort by Registered date (descending)')
      expect(page).to have_link('Relevance', href: '/search/items?sort=relevance')
      expect(page).to have_link('Druid', href: '/search/items?sort=druid')
    end
  end
end
