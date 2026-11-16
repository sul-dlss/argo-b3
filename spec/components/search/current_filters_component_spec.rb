# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CurrentFiltersComponent, type: :component do
  let(:component) { described_class.new(search_form:, pinned: false) }

  context 'when there are current filters' do
    let(:search_form) do
      ResultsSearchForm.new(
        query: 'test',
        object_types: %w[item collection],
        projects: ['Project 1']
      )
    end

    it 'renders the current filters and the pin button' do
      render_inline(component)

      expect(page).to have_css('section[aria-label="Current Filters"] h2.h6', exact_text: 'Your selections')
      expect(page).to have_css('li', text: 'test')
      expect(page).to have_css('li', text: /Object type\s+❯\s+item OR collection/)
      expect(page).to have_css('li', text: /Project\s+❯\s+Project 1/)
      expect(page).to have_button('Pin')
      expect(page).to have_link('Clear all', href: '/search')
    end
  end

  context 'when the search is advanced' do
    let(:search_form) { ResultsSearchForm.new(advanced: true, query: 'Miller OR octopus', projects: ['Project 1']) }

    it 'pins the advanced search and clears all to an empty advanced search' do
      render_inline(component)

      expect(page).to have_field('advanced', type: :hidden, with: 'true')
      expect(page).to have_button('Pin')
      expect(page).to have_link('Clear all', href: '/advanced_search?advanced=true')
    end
  end

  context 'when there are no current filters' do
    let(:search_form) { ResultsSearchForm.new }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
