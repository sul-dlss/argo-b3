# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::LoadingFieldValueResultsComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Projects')
  end

  it 'renders placeholders' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Loading Projects"]')
    expect(page).to have_css('ul.placeholder-glow li span.placeholder', count: 5)
    expect(heading_outline(page.native.to_html))
      .to eq [[2, 'Projects (Loading ...)'], [3, '1.'], [3, '2.'], [3, '3.'], [3, '4.'], [3, '5.']]
    expect(page).to have_css('h2.h3')
    expect(page).to have_css('li h3.h4', count: 5)
  end
end
