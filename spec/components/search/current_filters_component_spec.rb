# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CurrentFiltersComponent, type: :component do
  let(:component) { described_class.new(search_form:) }

  context 'when there are current filters' do
    let(:search_form) do
      SearchForm.new(
        query: 'test',
        include_google_books: true,
        object_types: %w[item collection],
        projects: ['Project 1']
      )
    end

    it 'renders the current filters' do
      render_inline(component)

      expect(page).to have_css('section[aria-label="Current Filters"]')
      expect(page).to have_css('li', text: 'test')
      expect(page).to have_css('li', text: 'Include Google Books')
      expect(page).to have_css('li', text: /Object types\s+❯\s+item/)
      expect(page).to have_css('li', text: /Object types\s+❯\s+collection/)
      expect(page).to have_css('li', text: /Projects\s+❯\s+Project 1/)
      expect(page).to have_link('Clear all', href: '/')
    end
  end

  context 'when there are no current filters' do
    let(:search_form) { SearchForm.new }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
