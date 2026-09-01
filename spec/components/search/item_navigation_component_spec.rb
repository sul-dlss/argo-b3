# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemNavigationComponent, type: :component do
  let(:component) do
    described_class.new(current_position:, total_results: 10, previous_druid:, next_druid:)
  end
  let(:current_position) { 3 }
  let(:previous_druid) { 'druid:bc123df4567' }
  let(:next_druid) { 'druid:cd234eg5678' }

  it 'renders the previous and next links, styled like links, and the current position' do
    render_inline(component)

    expect(page).to have_link('‹‹ Previous', href: "/objects/#{previous_druid}?search_position=2")
    expect(page).to have_link('Next ››', href: "/objects/#{next_druid}?search_position=4")
    expect(page).to have_css('a.btn-link', text: '‹‹ Previous')
    expect(page).to have_css('a.btn-link', text: 'Next ››')
    expect(page).to have_css('span', text: '3 of 10')
  end

  context 'when there is no previous item' do
    let(:previous_druid) { nil }

    it 'still shows the previous link, but disabled' do
      render_inline(component)

      expect(page).to have_css('a.disabled', text: '‹‹ Previous')
      expect(page).to have_link('‹‹ Previous', href: '#')
    end
  end

  context 'when there is no next item' do
    let(:next_druid) { nil }

    it 'still shows the next link, but disabled' do
      render_inline(component)

      expect(page).to have_css('a.disabled', text: 'Next ››')
      expect(page).to have_link('Next ››', href: '#')
    end
  end

  context 'when current_position is not present' do
    let(:current_position) { nil }

    it 'does not render' do
      expect(component.render?).to be false
    end
  end
end
