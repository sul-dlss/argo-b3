# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositStarter do
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, step: 'deposit', initiating_deposit_completed_at: 1.day.ago)
  end
  let(:deposit_form) { instance_double(MultiItemDeposit::DepositForm, version_description: 'Fixed typos') }
  let(:effective_groups) { ['workgroup:sdr:administrator-role'] }

  it 'saves the version description and starts initiating the deposit' do
    described_class.call(multi_item_deposit_action:, deposit_form:, effective_groups:)

    expect(multi_item_deposit_action.reload).to have_attributes(
      version_description: 'Fixed typos', initiating_deposit_state: 'initiating_depositing',
      initiating_deposit_started_at: be_within(1.second).of(Time.current), initiating_deposit_completed_at: nil
    )
  end

  it 'enqueues a deposit job' do
    described_class.call(multi_item_deposit_action:, deposit_form:, effective_groups:)

    expect(MultiItemDeposit::DepositJob).to have_been_enqueued.with(multi_item_deposit_action:, effective_groups:)
  end
end
