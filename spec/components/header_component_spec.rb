# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeaderComponent, type: :component do
  let(:component) { described_class.new }

  it 'renders the header' do
    render_inline(component)

    expect(page).to have_css('header .masthead .h1', text: 'Argo: Build Back Better')
    expect(page).to have_link(href: '/', text: 'Argo: Build Back Better')
    expect(page).to have_link(href: '/report', text: 'Report')
    expect(page).to have_link(href: '/workflow_grid', text: 'Workflow grid')
    expect(page).to have_link(href: 'mailto:argo-feedback@lists.stanford.edu', text: 'Feedback')
  end
end
