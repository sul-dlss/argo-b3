# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Pagination::BriefComponent, type: :component do
  let(:component) do
    described_class.new(current_page:, total_pages:, path_func:, total_results:, per_page: 20)
  end

  let(:path_func) { proc { |page| "/items?page=#{page}" } }

  context 'when there is only one page' do
    let(:current_page) { 1 }
    let(:total_pages) { 1 }
    let(:total_results) { 10 }

    it 'does not render' do
      expect(component.render?).to be false
    end
  end

  context 'when there are 2 pages and page 1 is current' do
    let(:current_page) { 1 }
    let(:total_pages) { 2 }
    let(:total_results) { 30 }

    it 'renders pagination' do
      render_inline(component)

      expect(page).to have_css('nav.pagination')

      expect(page).to have_link('« Previous', href: '#', class: 'page-link me-2 disabled') do |link|
        expect(link[:rel]).to eq 'prev'
        expect(link[:'aria-label']).to eq 'Go to previous page'
      end

      expect(page).to have_text(/1 -\s+20.+of.+30/m)

      expect(page).to have_link('Next »', href: '/items?page=2', class: 'page-link ms-2') do |link|
        expect(link[:rel]).to eq 'next'
        expect(link[:'aria-label']).to eq 'Go to next page'
      end
    end
  end

  context 'when there are 2 pages and page 2 is current' do
    let(:current_page) { 2 }
    let(:total_pages) { 2 }
    let(:total_results) { 30 }

    it 'renders pagination' do
      render_inline(component)

      expect(page).to have_link('« Previous', href: '/items?page=1', class: 'page-link me-2') do |link|
        expect(link[:rel]).to eq 'prev'
        expect(link[:'aria-label']).to eq 'Go to previous page'
      end

      expect(page).to have_text(/21 -\s+30.+of.+30/m)

      expect(page).to have_link('Next »', href: '#', class: 'page-link ms-2 disabled') do |link|
        expect(link[:rel]).to eq 'next'
        expect(link[:'aria-label']).to eq 'Go to next page'
      end
    end
  end
end
