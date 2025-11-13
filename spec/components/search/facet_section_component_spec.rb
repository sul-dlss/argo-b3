# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetSectionComponent, type: :component do
  let(:label) { 'Object Types' }

  context 'when collapsed' do
    let(:component) { described_class.new(label:) }

    it 'renders collapsed accordion' do
      render_inline(component) { 'some content' }

      expect(page).to have_css('section.accordion[aria-label="Object Types"] h3 button', text: label)
      expect(page).to have_css('div.accordion-collapse.collapse:not(.show)', text: 'some content')
    end
  end

  context 'when expanded' do
    let(:component) { described_class.new(label:, show: true) }

    it 'renders expanded accordion' do
      render_inline(component) { 'some content' }

      expect(page).to have_css('div.accordion-collapse.collapse.show', text: 'some content')
    end
  end
end
