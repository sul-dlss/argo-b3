# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DiscardButtonComponent, type: :component do
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, description: 'My deposit') }

  it 'renders the discard button, which deletes the deposit after confirming' do
    render_inline(described_class.new(multi_item_deposit_action:))

    expect(page).to have_css("a[href='/multi_item_deposit_actions/#{multi_item_deposit_action.id}']" \
                             '[data-turbo-method="delete"]' \
                             "[data-turbo-confirm^='Discard Multi-item deposit #{multi_item_deposit_action.id}: " \
                             "My deposit? ']", text: 'Discard')
    expect(page).to have_css('a i.bi-trash[aria-hidden="true"]')
  end
end
