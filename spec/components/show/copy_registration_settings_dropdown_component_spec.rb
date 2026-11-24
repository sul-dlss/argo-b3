# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::CopyRegistrationSettingsDropdownComponent, type: :component do
  subject(:component) { described_class.new(druid: 'druid:bc123df4567', disabled:) }

  let(:disabled) { false }

  it 'renders a dropdown that opens either registration form prefilled from the item' do
    render_inline(component)

    expect(page).to have_css('button.dropdown-toggle[data-bs-toggle="dropdown"]:not([disabled])',
                             text: 'Copy registration settings for')
    expect(page.all('.dropdown-menu a').map { [it.text.strip, it[:href]] }).to eq(
      [['Single item', '/items/new?from_druid=druid%3Abc123df4567'],
       ['Multiple items', '/multiple_items/new?from_druid=druid%3Abc123df4567']]
    )
  end

  context 'when disabled' do
    let(:disabled) { true }

    it 'renders a disabled dropdown toggle' do
      render_inline(component)

      expect(page).to have_button('Copy registration settings for', class: 'dropdown-toggle', disabled: true)
    end
  end
end
