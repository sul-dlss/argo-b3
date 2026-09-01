# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemNavigationComponent, type: :component do
  let(:component) do
    described_class.new(last_search_form:, current_position:, total_results: 10, previous_druid:, next_druid:)
  end
  let(:last_search_form) { instance_double(SearchForm, attributes: { query: 'cats', page: 2 }) }
  let(:current_position) { 3 }
  let(:previous_druid) { 'druid:bc123df4567' }
  let(:next_druid) { 'druid:cd234eg5678' }

  it 'renders navigation back to the search and between individual results' do
    render_inline(component)

    expect(page).to have_link('← Search results', href: /search\?page=2&query=cats/)
    expect(page).to have_link('« Previous', href: "/objects/#{previous_druid}?search_position=2")
    expect(page).to have_link('Next »', href: "/objects/#{next_druid}?search_position=4")
    expect(page).to have_css('span.fw-bold', text: '3 of 10')
  end

  context 'when there is no previous item' do
    let(:previous_druid) { nil }

    it 'renders a semantically disabled previous control' do
      render_inline(component)

      expect(page).to have_css('span[aria-disabled="true"]', text: '« Previous')
      expect(page).to have_no_link('« Previous')
    end
  end

  context 'when there is no next item' do
    let(:next_druid) { nil }

    it 'renders a semantically disabled next control' do
      render_inline(component)

      expect(page).to have_css('span[aria-disabled="true"]', text: 'Next »')
      expect(page).to have_no_link('Next »')
    end
  end

  context 'when item navigation is not present' do
    let(:current_position) { nil }

    it 'only renders navigation back to the search' do
      render_inline(component)

      expect(page).to have_link('← Search results')
      expect(page).to have_no_css('.item-search-navigation')
    end
  end

  context 'when the last search form is not present' do
    let(:last_search_form) { nil }

    it 'does not render' do
      expect(component.render?).to be false
    end
  end
end
