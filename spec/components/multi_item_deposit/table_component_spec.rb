# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::TableComponent, type: :component do
  include ActionView::RecordIdentifier

  let(:component) do
    described_class.new(multi_item_deposit_actions: MultiItemDepositAction.where(id: multi_item_deposit_action.id),
                        label: 'Deposits', id: 'deposits-table', show_label:)
  end
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, description: 'Maps') }
  let(:show_label) { false }

  it 'renders the table without a caption' do
    render_inline(component)

    table = page.find("table#deposits-table[aria-label='Deposits']")
    expect(table).to have_no_css('caption')
    expect(table.all('thead th').map { it.text.strip })
      .to eq(['Action', 'Description', 'Created', 'Submitted', 'Status', 'Workflow status'])
    row = table.find("tr##{dom_id(multi_item_deposit_action, 'row')}")
    expect(row).to have_css("td:nth-of-type(1) a[href='/multi_item_deposit_actions/#{multi_item_deposit_action.id}']",
                            exact_text: "Multi-item deposit #{multi_item_deposit_action.id}")
    expect(row).to have_css('td:nth-of-type(2)', exact_text: 'Maps')
    expect(row).to have_css('td:nth-of-type(5)', text: 'Not submitted')
  end

  context 'when showing the label' do
    let(:show_label) { true }

    it 'renders the caption' do
      render_inline(component)

      expect(page).to have_css('table#deposits-table caption', text: 'Deposits')
    end
  end

  context 'when there are no Multi-Item Deposits' do
    let(:component) do
      described_class.new(multi_item_deposit_actions: MultiItemDepositAction.none, label: 'Deposits',
                          id: 'deposits-table')
    end

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_css('p', text: 'No multi-item deposits yet')
    end
  end
end
