# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::SectionComponent, type: :component do
  context 'when not pinned' do
    it 'renders an expanded collapsible section with the heading and content' do
      render_inline(described_class.new(id: 'recent-objects-section', label: 'Recently viewed')) { 'The content' }

      button = page.find('h2 button[aria-controls="recent-objects-section"][aria-expanded="true"]')
      expect(button).to have_text('Recently viewed')
      expect(button).to have_no_css('.bi-pin-fill')
      expect(page).to have_css('div#recent-objects-section.collapse.show', text: 'The content')
    end
  end

  context 'when pinned' do
    it 'renders a pin icon in the heading' do
      render_inline(described_class.new(id: 'pinned-items-section', label: 'Pinned items', pinned: true)) do
        'The content'
      end

      expect(page).to have_css('h2 button', text: 'Pinned items')
      expect(page).to have_css('h2 button .bi-pin-fill[aria-hidden="true"]')
    end
  end
end
