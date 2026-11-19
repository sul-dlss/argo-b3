# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::LinkTabsComponent, type: :component do
  it 'renders a link for each tab, marking the active tab as the current page' do
    render_inline(described_class.new(classes: 'mb-4')) do |component|
      component.with_tab(label: 'First', path: '/first')
      component.with_tab(label: 'Second', path: '/second', active: true)
    end

    expect(page).to have_css('ul.nav.nav-underline.mb-4 li.nav-item', count: 2)
    expect(page).to have_css('a.nav-link:not(.active):not([aria-current])[href="/first"]', text: 'First')
    expect(page).to have_css('a.nav-link.active[aria-current="page"][href="/second"]', text: 'Second')
  end
end
