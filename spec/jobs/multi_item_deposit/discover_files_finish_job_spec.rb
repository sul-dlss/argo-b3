# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DiscoverFilesFinishJob do
  subject(:job) { described_class.new }

  let(:user) { create(:user) }
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user:, discovery_state: 'discovering') }

  before do
    first_content = create(:content, druid: 'druid:bc123df4567')
    second_content = create(:content, druid: 'druid:gh456jk7890')
    create(:content_file_binary, content: first_content, filepath: 'file1.txt', size: 10)
    create(:content_file_binary, content: first_content, filepath: 'file2.txt', size: 20)
    create(:content_file_binary, content: second_content, filepath: 'file1.txt', size: 5)
    # Content not in this Multi-Item Deposit.
    create(:content_file_binary, size: 1000)
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', content: first_content)
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:gh456jk7890', content: second_content)
    # Item Deposit with discovery errors has no Content.
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:mn789pq0123',
                                 discovery_errors: ['Object not found'])
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  it 'completes discovery and notifies the user' do
    job.perform(multi_item_deposit_action:)

    expect(multi_item_deposit_action.reload).to have_attributes(
      discovery_state: 'discovery_not_in_progress', size: 35,
      discovery_completed_at: be_within(1.second).of(Time.current)
    )
    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with('notifications', user, target: 'toast-container', html: include('Completed discovering files'))
  end
end
