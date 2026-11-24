# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::TabsComponent, type: :component do
  context 'when the recent tab is active' do
    it 'renders the recent tab as the current page' do
      render_inline(described_class.new(active: :recent))

      expect(page).to have_css('ul.nav.nav-underline li.nav-item', count: 2)
      expect(page).to have_css('a.nav-link.active[aria-current="page"][href="/notifications"]', text: 'Recent')
      expect(page).to have_css('a.nav-link:not(.active):not([aria-current])[href="/notifications/email_settings"]',
                               text: 'Email settings')
    end
  end

  context 'when the email settings tab is active' do
    it 'renders the email settings tab as the current page' do
      render_inline(described_class.new(active: :email_settings))

      expect(page).to have_css('a.nav-link:not(.active):not([aria-current])[href="/notifications"]', text: 'Recent')
      expect(page).to have_css('a.nav-link.active[aria-current="page"][href="/notifications/email_settings"]',
                               text: 'Email settings')
    end
  end
end
