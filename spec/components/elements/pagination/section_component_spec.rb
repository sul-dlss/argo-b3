# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Pagination::SectionComponent, type: :component do
  let(:component) do
    described_class.new(current_page:, total_pages:, path_func:)
  end

  let(:path_func) { proc { |page| "/items?page=#{page}" } }

  context 'when there is only one page' do
    let(:current_page) { 1 }
    let(:total_pages) { 1 }

    it 'does not render' do
      expect(component.render?).to be false
    end
  end

  context 'when there are 2 pages and page 1 is current' do
    let(:current_page) { 1 }
    let(:total_pages) { 2 }

    it 'renders pagination' do
      render_inline(component)

      expect(page).to have_css('nav.paginate-section[aria-label="Pagination links"] ul.pagination')
      items = page.all('ul.pagination li.page-item')
      expect(items.size).to eq 4

      prev_item = items[0]
      expect(prev_item[:class]).to eq 'page-item disabled'
      expect(prev_item).to have_link('« Previous', href: '#', class: 'page-link') do |link|
        expect(link[:rel]).to eq 'prev'
        expect(link[:'aria-label']).to eq 'Go to previous page'
      end

      current_item = items[1]
      expect(current_item[:class]).to eq 'page-item active'
      expect(current_item).to have_link('1', href: '/items?page=1', class: 'page-link') do |link|
        expect(link[:'aria-label']).to eq 'Current page, Page 1'
      end

      not_current_item = items[2]
      expect(not_current_item[:class]).to eq 'page-item'
      expect(not_current_item).to have_link('2', href: '/items?page=2', class: 'page-link') do |link|
        expect(link[:'aria-label']).to eq 'Go to page 2'
      end

      next_item = items[3]
      expect(next_item[:class]).to eq 'page-item'
      expect(next_item).to have_link('Next »', href: '/items?page=2', class: 'page-link') do |link|
        expect(link[:rel]).to eq 'next'
        expect(link[:'aria-label']).to eq 'Go to next page'
      end
    end
  end

  context 'when there are 2 pages and page 2 is current' do
    let(:current_page) { 2 }
    let(:total_pages) { 2 }

    it 'renders pagination' do
      render_inline(component)

      items = page.all('ul.pagination li.page-item')
      expect(items.size).to eq 4

      prev_item = items[0]
      expect(prev_item[:class]).to eq 'page-item'
      expect(prev_item).to have_link('« Previous', href: '/items?page=1')

      current_item = items[1]
      expect(current_item[:class]).to eq 'page-item'
      expect(current_item).to have_link('1') do |link|
        expect(link[:'aria-label']).to eq 'Go to page 1'
      end

      not_current_item = items[2]
      expect(not_current_item[:class]).to eq 'page-item active'
      expect(not_current_item).to have_link('2') do |link|
        expect(link[:'aria-label']).to eq 'Current page, Page 2'
      end

      next_item = items[3]
      expect(next_item[:class]).to eq 'page-item disabled'
      expect(next_item).to have_link('Next »', href: '#')
    end
  end

  context 'when there are 7 pages' do
    let(:current_page) { 1 }
    let(:total_pages) { 7 }

    it 'renders pagination without ellipses' do
      render_inline(component)

      expect(page).to have_css('ul.pagination li.page-item', count: 9)
      expect(page).to have_no_css('ul.pagination li.page-item.disabled', text: '…')
    end
  end

  context 'when there are 8 pages and current page is 1' do
    let(:current_page) { 1 }
    let(:total_pages) { 8 }

    it 'renders pagination with ellipses' do
      render_inline(component)

      expect(page).to have_css('ul.pagination li.page-item.disabled', text: '...', count: 1)
      expect(page.all('ul.pagination li.page-item')[6]).to have_text('...')
    end
  end

  context 'when there are 8 pages and current page is 2' do
    let(:current_page) { 2 }
    let(:total_pages) { 8 }

    it 'renders pagination with ellipses' do
      render_inline(component)

      expect(page).to have_css('ul.pagination li.page-item.disabled', text: '...', count: 1)
      expect(page.all('ul.pagination li.page-item')[6]).to have_text('...')
    end
  end

  context 'when there are 8 pages and current page is 8' do
    let(:current_page) { 8 }
    let(:total_pages) { 8 }

    it 'renders pagination with ellipses' do
      render_inline(component)

      expect(page).to have_css('ul.pagination li.page-item.disabled', text: '...', count: 1)
      expect(page.all('ul.pagination li.page-item')[3]).to have_text('...')
    end
  end

  context 'when there are 100 pages and current page is 50' do
    let(:current_page) { 50 }
    let(:total_pages) { 100 }

    it 'renders pagination with ellipses' do
      render_inline(component)

      expect(page).to have_css('ul.pagination li.page-item.disabled', text: '...', count: 2)
      expect(page.all('ul.pagination li.page-item')[3]).to have_text('...')
      expect(page.all('ul.pagination li.page-item')[9]).to have_text('...')
    end
  end
end
