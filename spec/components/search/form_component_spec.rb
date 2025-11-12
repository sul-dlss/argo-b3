# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FormComponent, type: :component do
  let(:component) { described_class.new(search_form:, url: '/search', label: 'Search') }
  let(:search_form) { Search::ItemForm.new(query: 'test', projects: ['Google Books']) }

  it 'renders the search form' do
    render_inline(component)

    expect(page).to have_css("form[action='/search']")
    expect(page).to have_field('search[projects][]', type: :hidden, with: 'Google Books')
    expect(page).to have_field('Search', type: :text, with: 'test')
    expect(page).to have_field('Include Google Books', type: :checkbox, checked: false)
    expect(page).to have_button('Search')
  end
end
