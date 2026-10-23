# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::TableComponent, type: :component do
  include ActionView::RecordIdentifier

  let(:component) do
    described_class.new(multi_item_deposit_actions: MultiItemDepositAction.where(id: multi_item_deposit_action.id),
                        label: 'Deposits', id: 'deposits-table', show_user:, show_label:)
  end
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, user: create(:user, email_address: 'mmouse@stanford.edu'))
  end
  let(:show_user) { false }
  let(:show_label) { false }

  it 'renders the table without the user column or caption' do
    render_inline(component)

    table = page.find("table#deposits-table[aria-label='Deposits']")
    expect(table).to have_no_css('caption')
    expect(table).to have_css('thead th', count: 5)
    expect(table).to have_no_css('thead th', text: 'User')
    expect(table).to have_css("tr##{dom_id(multi_item_deposit_action, 'row')} td:nth-of-type(4)",
                              text: 'Not submitted')
  end

  context 'when showing the user and label' do
    let(:show_user) { true }
    let(:show_label) { true }

    it 'renders the user column and caption' do
      render_inline(component)

      table = page.find('table#deposits-table')
      expect(table).to have_css('caption', text: 'Deposits')
      expect(table).to have_css('thead th:nth-of-type(2)', text: 'User')
      expect(table).to have_css("tr##{dom_id(multi_item_deposit_action, 'row')} td:nth-of-type(2)", text: 'mmouse')
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
