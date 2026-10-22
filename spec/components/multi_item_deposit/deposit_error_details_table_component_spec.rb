# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositErrorDetailsTableComponent, type: :component do
  let(:component) { described_class.new(multi_item_deposit_action:) }
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  context 'when Item Deposits have deposit errors' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:cd234fg5678', manifest_line_number: 3,
                                   deposit_errors: ['Version cannot be opened', 'Object is locked'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', manifest_line_number: 2,
                                   deposit_errors: ['Object not found'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:df345gh6789', manifest_line_number: 4)
      # Another Multi-Item Deposit's Item Deposit.
      create(:item_deposit_action, druid: 'druid:gh567jk8901', deposit_errors: ['Object not found'])
    end

    it 'renders a row for each Item Deposit with deposit errors' do
      render_inline(component)

      table = page.find('table[aria-label="Error details"]')
      expect(table).to have_css('caption', text: 'Error details')
      expect(table.all('th').map { |header| header.text.strip }).to eq(%w[Druid Error])

      rows = table.all('tbody tr')
      expect(rows.map { |row| row.first('td').text.strip }).to eq(%w[bc123df4567 cd234fg5678])

      expect(rows[0]).to have_css('ul li span.text-danger', text: 'Object not found')
      expect(rows[1]).to have_css('ul li span.text-danger', text: 'Version cannot be opened')
      expect(rows[1]).to have_css('ul li span.text-danger', text: 'Object is locked')
    end
  end

  context 'when no Item Deposits have deposit errors' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:)
    end

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_table
    end
  end
end
