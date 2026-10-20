# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositFinishJob do
  subject(:job) { described_class.new }

  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, initiating_deposit_state: 'initiating_depositing')
  end

  it 'completes initiating the deposit' do
    job.perform(multi_item_deposit_action:)

    expect(multi_item_deposit_action.reload).to have_attributes(
      initiating_deposit_state: 'initiating_deposit_not_in_progress',
      initiating_deposit_completed_at: be_within(1.second).of(Time.current)
    )
  end
end
