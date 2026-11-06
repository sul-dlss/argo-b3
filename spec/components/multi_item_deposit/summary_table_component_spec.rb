# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::SummaryTableComponent, type: :component do
  let(:component) { described_class.new(multi_item_deposit_action:) }
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  context 'when there are Item Deposits' do
    before do
      content = create(:content, druid: 'druid:cd234fg5678')
      create(:content_file_binary, content:, filepath: 'image1.tif')
      create(:content_file_binary, content:, filepath: 'image2.tif')
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:cd234fg5678', manifest_line_number: 3,
                                   path: 'folder3', content:, content_type: 'image', initial_version: false)
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', manifest_line_number: 2,
                                   path: 'folder2', content: create(:content, druid: 'druid:bc123df4567'),
                                   content_type: 'book', initial_version: true)
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:df345gh6789', manifest_line_number: 4,
                                   path: 'folder4')
      # Another Multi-Item Deposit's Item Deposit.
      create(:item_deposit_action, druid: 'druid:gh567jk8901')
    end

    it 'renders a row for each Item Deposit in manifest order' do
      render_inline(component)

      table = page.find('table[aria-label="Summary"]')
      expect(table).to have_css('caption', text: 'Summary')
      expect(table.all('th').map { |header| header.text.strip })
        .to eq(['Druid', 'Folder', 'Number of files', 'Content type', 'Deposit type', 'Status'])
      expect(table.all('tbody tr').map { |row| row.all('td').map { |cell| cell.text.strip } })
        .to eq([['bc123df4567', 'folder2', '0', 'book', 'new item', ''],
                ['cd234fg5678', 'folder3', '2', 'image', 'redeposit', ''],
                ['df345gh6789', 'folder4', '0', '', 'redeposit', '']])
    end
  end

  context 'when Item Deposits have structure errors or warnings' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', manifest_line_number: 2,
                                   structural_csv_errors: ['Row 2: Missing filename'],
                                   content_type_structure_errors: ['Page has more than one image'],
                                   content_type_structure_warnings: ['No displayable image'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:cd234fg5678', manifest_line_number: 3,
                                   content_type_structure_warnings: ['No displayable image'])
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:df345gh6789', manifest_line_number: 4)
    end

    it 'lists them in the status column of the Item Deposit row' do
      render_inline(component)

      rows = page.all('table[aria-label="Summary"] tbody tr')
      expect(rows.map { |row| row.first('td').text.strip }).to eq(%w[bc123df4567 cd234fg5678 df345gh6789])

      status_cells = rows.map { |row| row.all('td').last }
      expect(status_cells[0].all('ul li span.text-danger').map(&:text))
        .to eq(['Row 2: Missing filename', 'Page has more than one image'])
      expect(status_cells[0]).to have_css('ul li span:not(.text-danger)', text: 'No displayable image')
      expect(status_cells[1]).to have_css('ul li span:not(.text-danger)', text: 'No displayable image')
      expect(status_cells[2].text.strip).to be_empty
    end
  end
end
