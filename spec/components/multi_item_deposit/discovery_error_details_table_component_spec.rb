# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DiscoveryErrorDetailsTableComponent, type: :component do
  let(:component) { described_class.new(multi_item_deposit_action:) }
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  context 'when Item Deposits have discovery errors or warnings' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:cd234fg5678', path: 'folder2',
                                   manifest_line_number: 3,
                                   discovery_errors: ['Object not found'], discovery_warnings: ['Empty files: a.txt'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', path: 'folder1',
                                   manifest_line_number: 2, discovery_errors: ['Not an Item'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:df345gh6789', path: 'folder3',
                                   manifest_line_number: 4, discovery_warnings: ['Version cannot be opened'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:fg456hj7890', path: 'folder4',
                                   manifest_line_number: 5)
      # Another Multi-Item Deposit's Item Deposit.
      create(:item_deposit_action, druid: 'druid:gh567jk8901', discovery_warnings: ['Version cannot be opened'])
    end

    it 'renders a row for each Item Deposit with errors or warnings' do
      render_inline(component)

      table = page.find('table[aria-label="Error details"]')
      expect(table).to have_css('caption', text: 'Error details')
      expect(table.all('th').map { |header| header.text.strip })
        .to eq(['Manifest line number', 'Druid', 'Folder', 'Error'])

      rows = table.all('tbody tr')
      expect(rows.map { |row| row.all('td').first(3).map { |cell| cell.text.strip } })
        .to eq([%w[2 bc123df4567 folder1], %w[3 cd234fg5678 folder2], %w[4 df345gh6789 folder3]])

      # Only errors are styled as errors.
      expect(rows[0]).to have_css('ul li span.text-danger', text: 'Not an Item')

      expect(rows[1]).to have_css('ul li span.text-danger', text: 'Object not found')
      expect(rows[1]).to have_css('ul li span:not(.text-danger)', text: 'Empty files: a.txt')

      expect(rows[2]).to have_css('ul li span:not(.text-danger)', text: 'Version cannot be opened')
    end
  end

  context 'when no Item Deposits have discovery errors or warnings' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:)
    end

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_table
    end
  end
end
