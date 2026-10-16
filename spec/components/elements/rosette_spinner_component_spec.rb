# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::RosetteSpinnerComponent, type: :component do
  it 'renders a small rosette spinner' do
    render_inline(described_class.new(size: :small, message: 'Structuring files...', classes: 'my-class'))

    expect(page).to have_css('div.my-class img[src$="/styles/Rosette.svg"]' \
                             '[style="height: 32px; width: 32px; --bs-spinner-animation-speed: 2.0s;"]')
    expect(page).to have_text('Structuring files...')
  end

  it 'renders a large rosette spinner' do
    render_inline(described_class.new(size: :large))

    expect(page).to have_css('img[src$="/styles/Rosette.svg"][style^="height: 192px; width: 192px;"]')
  end

  context 'with an unknown size' do
    it 'raises' do
      expect { described_class.new(size: :medium) }.to raise_error(KeyError)
    end
  end
end
