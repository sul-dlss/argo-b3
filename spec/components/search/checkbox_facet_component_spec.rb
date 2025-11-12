# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CheckboxFacetComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Test Label', facet_counts:, search_form:, form_field: :object_types)
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

    expect(page).to have_css('section[aria-label="Test Label"] h3', text: 'Test Label')

    expect(page).to have_css('form[action="/search/items"][method="get"]')
    expect(page).to have_field('search[query]', with: 'test', type: 'hidden')
    expect(page).to have_field('collection (10)', type: 'checkbox', checked: true)
    expect(page).to have_field('item (5)', type: 'checkbox', checked: false)
  end

  context 'when there are no facet counts' do
    let(:facet_counts) { [] }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
