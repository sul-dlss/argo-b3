# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Navigation::MegaMenuComponent, type: :component do
  it 'renders a dropdown toggle and a panel of sections of links, marking the current page and featured sections' do
    with_request_url '/bulk_actions' do
      render_inline(described_class.new(text: 'My menu')) do |menu|
        menu.with_section(label: 'First section') do |section|
          section.with_link(label: 'First', link: '/workflow_grid')
          section.with_link(label: 'Second', link: '/bulk_actions')
        end
        menu.with_section(label: 'Second section', featured: true) do |section|
          section.with_link(label: 'Third', link: '/report')
        end
      end
    end

    expect(page).to have_css('li.nav-item.dropdown button.dropdown-toggle[data-bs-toggle="dropdown"]',
                             exact_text: 'My menu')
    expect(page).to have_css('.dropdown-menu .row .col', count: 2)

    first_section, second_section = page.all('.dropdown-menu .col')
    expect(first_section).to have_css('.mega-menu-section:not(.mega-menu-section-featured)')
    expect(first_section).to have_css('[role="heading"]', exact_text: 'First section')
    expect(first_section).to have_css('li a.dropdown-item:not([aria-current]):not(.fw-bold)[href="/workflow_grid"]',
                                      exact_text: 'First')
    expect(first_section).to have_css('li a.dropdown-item[aria-current="page"]:not(.fw-bold)[href="/bulk_actions"]',
                                      exact_text: 'Second')
    expect(second_section).to have_css('[role="heading"]', exact_text: 'Second section')
    expect(second_section).to have_css('.mega-menu-section.mega-menu-section-featured')
    expect(second_section).to have_css('li a.dropdown-item.fw-bold[href="/report"]', exact_text: 'Third')
  end
end
