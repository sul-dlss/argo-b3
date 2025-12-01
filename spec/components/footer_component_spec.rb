# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FooterComponent, type: :component do
  let(:component) { described_class.new }

  it 'renders the footer' do
    render_inline(component)

    expect(page).to have_css('footer .copyright', text: '© Stanford University')
  end
end
