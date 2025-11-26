# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::LoadingItemResultsComponent, type: :component do
  let(:component) do
    described_class.new
  end

  it 'renders placeholders' do
    render_inline(component)

    expect(page).to have_css('section[aria-label="Loading item, collection, and admin policy results"]')
    expect(page).to have_css('ul.placeholder-glow li table caption span.placeholder', count: 3)
    table = page.first('table')
    expect(table).to have_css('tr th span.placeholder', count: 10)
    expect(table).to have_css('tr td span.placeholder', count: 10)
  end
end
