# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CurrentFiltersComponent, type: :component do
  let(:component) { described_class.new(search_form:) }

  context 'when there are current filters' do
    let(:search_form) do
      Search::ItemForm.new(
        object_types: %w[item collection],
        projects: ['Project 1']
      )
    end

    it 'renders the current filters' do
      render_inline(component)

      expect(page).to have_css('section[aria-label="Current Filters"]')
      expect(page).to have_css('li', text: /Object types:\s+item/)
      expect(page).to have_css('li', text: /Object types:\s+collection/)
      expect(page).to have_css('li', text: /Projects:\s+Project 1/)
    end
  end

  context 'when there are no current filters' do
    let(:search_form) { Search::ItemForm.new }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
