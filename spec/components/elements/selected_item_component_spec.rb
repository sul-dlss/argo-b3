# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::SelectedItemComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Test Label', path: '/remove/path')
  end

  it 'renders the selected item with label and remove link' do
    render_inline(component)

    expect(page).to have_css('li .selected-item-label', text: 'Test Label')
    expect(page).to have_link('', href: '/remove/path', title: 'Remove Test Label', class: 'btn-close')
  end
end
