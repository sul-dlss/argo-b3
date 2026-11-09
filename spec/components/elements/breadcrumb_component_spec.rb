# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::BreadcrumbComponent, type: :component do
  it 'renders a breadcrumb nav linking to the page with a hidden arrow' do
    render_inline(described_class.new(label: 'Bulk actions', link: '/bulk_actions'))

    nav = page.find('nav[aria-label="Breadcrumb"]')
    expect(nav).to have_link('← Bulk actions', href: '/bulk_actions', class: 'btn-link')
    expect(nav).to have_css('a span[aria-hidden="true"]', text: '←')
  end
end
