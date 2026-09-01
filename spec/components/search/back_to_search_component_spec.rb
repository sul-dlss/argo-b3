# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::BackToSearchComponent, type: :component do
  let(:component) { described_class.new(last_search_form: search_form) }
  let(:search_form) { instance_double(SearchForm, attributes: { query: 'cats', page: 2 }) }

  it 'renders the search results button with left arrow, styled like a link' do
    render_inline(component)
    expect(page).to have_css('a.btn-link', text: '← Search results')
    expect(page).to have_link('← Search results', href: /search\?page=2&query=cats/)
  end

  context 'when last_search_form is not present' do
    let(:search_form) { nil }

    it 'does not render' do
      expect(component.render?).to be false
    end
  end
end
