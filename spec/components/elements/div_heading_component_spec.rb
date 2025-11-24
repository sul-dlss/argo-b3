# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::DivHeadingComponent, type: :component do
  let(:component) do
    described_class.new(level: 2, label: 'Test heading', classes: 'fw-bold', data: { test: 'value' })
  end

  it 'renders a div with role heading and aria-level' do
    render_inline(component)

    expect(page).to have_css('div[role="heading"][aria-level="2"][data-test="value"].fw-bold', text: 'Test heading')
  end
end
