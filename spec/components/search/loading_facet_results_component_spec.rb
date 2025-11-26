# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::LoadingFacetResultsComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Projects')
  end

  it 'renders placeholders' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Loading Projects"]')
    expect(page).to have_css('ul.placeholder-glow li span.placeholder', count: 5)
  end
end
