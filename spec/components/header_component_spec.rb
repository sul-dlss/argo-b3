# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeaderComponent, type: :component do
  let(:component) { described_class.new }

  it 'renders the header' do
    render_inline(component)

    within('header .masthead') do
      expect(page).to have_link(href: root_path, text: 'Argo: Build Back Better')
    end
  end
end
