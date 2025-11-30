# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeaderComponent, type: :component do
  let(:component) { described_class.new }

  it 'renders the header' do
    render_inline(component)

    expect(page).to have_css('header .masthead .h1', text: 'Argo')
  end
end
