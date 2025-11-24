# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Pagination::PageItemComponent, type: :component do
  let(:component) do
    described_class.new(page: 2, path:, current_page:)
  end
  let(:path) { '/some/path?page=2' }
  let(:current_page) { false }

  context 'when not the current page' do
    it 'renders the page item link' do
      render_inline(component)

      expect(page).to have_link('2', href: '/some/path?page=2', class: 'page-link') do |link|
        expect(link['aria-label']).to eq('Go to page 2')
      end
      expect(page).to have_css('li.page-item:not(.active):not([aria-current="page"]) a')
    end
  end

  context 'when the current page' do
    let(:current_page) { true }

    it 'renders the active page item' do
      render_inline(component)

      expect(page).to have_link('2', href: '/some/path?page=2', class: 'page-link') do |link|
        expect(link['aria-label']).to eq('Current page, Page 2')
      end
      expect(page).to have_css('li[aria-current="page"].page-item.active a')
    end
  end
end
