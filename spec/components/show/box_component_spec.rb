# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::BoxComponent, type: :component do
  let(:component) { described_class.new(heading: 'Tags') }

  it 'renders the heading and yielded content within the box' do
    render_inline(component) { '<li>Testing 1-2-3</li>'.html_safe }

    expect(page).to have_css('.card.object-type-border.object-type-bg-light h2.card-title', text: 'Tags')
    expect(page).to have_css('.card-body li', text: 'Testing 1-2-3')
  end
end
