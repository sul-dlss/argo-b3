# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::SummaryRowsComponent, type: :component do
  let(:component) { described_class.new(item_deposit_action:, file_count: 2) }
  # Rendered within a table, since table rows are dropped when rendered as a standalone fragment.
  let(:table) do
    Capybara.string("<table><tbody>#{component.render_in(vc_test_view_context)}</tbody></table>")
  end
  let(:rows) { table.all('tr') }

  context 'when the Item Deposit has no structure errors or warnings' do
    let(:item_deposit_action) do
      build(:item_deposit_action, druid: 'druid:bc123df4567', content_type: 'book', initial_version: true)
    end

    it 'renders the summary row only' do
      expect(rows.size).to eq(1)
      expect(rows.first.all('td').map { |cell| cell.text.strip }).to eq(['bc123df4567', '2', 'book', 'new item'])
    end
  end

  context 'when the Item Deposit has structure errors and warnings' do
    let(:item_deposit_action) do
      build(:item_deposit_action, druid: 'druid:bc123df4567', content_type: 'book', initial_version: false,
                                  structural_csv_errors: ['Row 2: Missing filename'],
                                  content_type_structure_errors: ['Page has more than one image'],
                                  content_type_structure_warnings: ['No displayable image'])
    end

    it 'renders a row listing them after the summary row' do
      expect(rows.size).to eq(2)
      expect(rows.first).to have_css('td', text: 'redeposit')
      expect(rows.last).to have_css('td[colspan="4"]')
      expect(rows.last.all('ul li span.text-danger').map(&:text))
        .to eq(['Row 2: Missing filename', 'Page has more than one image'])
      expect(rows.last).to have_css('ul li span:not(.text-danger)', text: 'No displayable image')
    end
  end
end
