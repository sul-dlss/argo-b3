# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::MultiItemDepositsTableComponent, type: :component do
  include ActionView::RecordIdentifier

  let(:component) { described_class.new(multi_item_deposit_actions:) }

  context 'when there are Multi-Item Deposits' do
    let(:multi_item_deposit_actions) { MultiItemDepositAction.where(id: multi_item_deposit_action.id) }
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, description: 'Maps') }

    it 'renders the table and a link to all Multi-Item Deposits' do
      render_inline(component)

      table = page.find("table#multi-item-deposits-table[aria-label='Multi-item deposits']")
      expect(table).to have_css('caption', text: 'Multi-item deposits')
      expect(table).to have_css('thead th', count: 5)
      expect(table).to have_no_css('thead th', text: 'User')
      expect(table).to have_css("tr##{dom_id(multi_item_deposit_action, 'row')} td:nth-of-type(1) a",
                                text: "Multi-item deposit #{multi_item_deposit_action.id}: Maps")
      expect(page).to have_link('View all multi-item deposits', href: '/multi_item_deposit_actions')
    end
  end

  context 'when there are no Multi-Item Deposits' do
    let(:multi_item_deposit_actions) { MultiItemDepositAction.none }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_table
      expect(page).to have_no_link('View all multi-item deposits')
    end
  end
end
