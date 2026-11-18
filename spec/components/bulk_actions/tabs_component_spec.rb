# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::TabsComponent, type: :component do
  context 'when the history tab is active' do
    it 'renders the history tab as the current page' do
      render_inline(described_class.new(active: :history))

      expect(page).to have_css('ul.nav.nav-underline li.nav-item', count: 2)
      expect(page).to have_css('a.nav-link.active[aria-current="page"][href="/bulk_actions"]',
                               text: 'Recent bulk actions')
      expect(page).to have_css('a.nav-link:not(.active):not([aria-current])[href="/bulk_actions/new"]',
                               text: 'Bulk action menu')
    end
  end

  context 'when the menu tab is active' do
    it 'renders the menu tab as the current page' do
      render_inline(described_class.new(active: :menu))

      expect(page).to have_css('a.nav-link:not(.active):not([aria-current])[href="/bulk_actions"]',
                               text: 'Recent bulk actions')
      expect(page).to have_css('a.nav-link.active[aria-current="page"][href="/bulk_actions/new"]',
                               text: 'Bulk action menu')
    end
  end

  context 'when the active tab is invalid' do
    it 'raises an error' do
      expect { described_class.new(active: :other) }.to raise_error(ArgumentError)
    end
  end
end
