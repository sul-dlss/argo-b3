# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CheckboxFacetComponent, type: :component do
  let(:component) do
    described_class.new(facet_counts:, search_form:, form_field: :object_types)
  end
  let(:search_form) { Search::ItemForm.new(object_types: ['collection'], page: 2, query: 'test') }
  let(:facet_counts) do
    [
      SearchResults::FacetCount.new(value: 'collection', count: 10),
      SearchResults::FacetCount.new(value: 'item', count: 5)
    ]
  end

  it 'renders the facet' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Object types"] h3', text: 'Object types')

    expect(page).to have_css('form[action="/search/items"][method="get"]')
    expect(page).to have_field('search[query]', with: 'test', type: 'hidden')
    expect(page).to have_field('collection', type: 'checkbox', checked: true)
    expect(page).to have_field('item', type: 'checkbox', checked: false)
    check_section = page.first('.facet-values .form-check')
    expect(check_section).to have_css('label.form-check-label', text: 'collection')
    expect(check_section).to have_css('.facet-count', text: '10')
  end

  context 'when there are no facet counts' do
    let(:facet_counts) { [] }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
