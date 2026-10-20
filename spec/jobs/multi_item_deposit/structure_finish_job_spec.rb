# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::StructureFinishJob do
  subject(:job) { described_class.new }

  let(:user) { create(:user) }
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user:, structuring_state: 'structuring') }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  it 'completes structuring and notifies the user' do
    job.perform(multi_item_deposit_action:)

    expect(multi_item_deposit_action.reload).to have_attributes(
      structuring_state: 'structuring_not_in_progress',
      structuring_completed_at: be_within(1.second).of(Time.current)
    )
    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with('notifications', user, target: 'toast-container', html: include('Completed building structure'))
  end
end
