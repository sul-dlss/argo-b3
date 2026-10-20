# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DiscoveryStarter do
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, structuring_started_at: 1.day.ago, structuring_completed_at: 1.day.ago,
                                       discovery_completed_at: 1.day.ago)
  end
  let(:attributes) do
    { description: 'My deposit', file_location: 'mount', mount_path: '/dor/staging/deposit', manifest_source: 'mount',
      manifest_csv: "druid,folder_name\ndruid:bc123df4567,folder1\ndruid:cd234fg5678,folder2\n" }
  end
  let(:discovery_form) { instance_double(MultiItemDeposit::DiscoveryForm, multi_item_deposit_action_attributes: attributes) }
  let(:effective_groups) { ['sdr:test-workgroup'] }
  let!(:existing_content) { create(:content, druid: 'druid:fg345hj6789') }
  let!(:unrelated_content) { create(:content, druid: 'druid:gh456jk7890') }
  let!(:existing_item_deposit_action) do
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:fg345hj6789', content: existing_content)
  end

  # The test database has no queue tables, so a verifying double (which loads the schema) cannot be used.
  # The block enqueues to the test adapter.
  let(:batch_class) { double('SolidQueue::Batch') } # rubocop:disable RSpec/VerifiedDoubles

  before do
    stub_const('SolidQueue::Batch', batch_class)
    allow(batch_class).to receive(:enqueue).and_yield
  end

  it 'replaces the Item Deposits and starts discovery' do
    described_class.call(multi_item_deposit_action:, discovery_form:, effective_groups:)

    expect(ItemDepositAction.exists?(existing_item_deposit_action.id)).to be false
    expect(Content.exists?(existing_content.id)).to be false
    expect(Content.exists?(unrelated_content.id)).to be true

    expect(multi_item_deposit_action.reload).to have_attributes(
      description: 'My deposit', mount_path: '/dor/staging/deposit', manifest_source: 'mount',
      manifest_csv: "druid,folder_name\ndruid:bc123df4567,folder1\ndruid:cd234fg5678,folder2\n",
      structuring_started_at: nil, structuring_completed_at: nil,
      discovery_state: 'discovering', discovery_started_at: be_within(1.second).of(Time.current),
      discovery_completed_at: nil
    )
    expect(multi_item_deposit_action.item_deposit_actions.order(:manifest_line_number)
                                    .pluck(:druid, :path, :manifest_line_number))
      .to eq([['druid:bc123df4567', 'folder1', 2], ['druid:cd234fg5678', 'folder2', 3]])
  end

  it 'enqueues a batch of discover files jobs' do
    described_class.call(multi_item_deposit_action:, discovery_form:, effective_groups:)

    expect(batch_class).to have_received(:enqueue)
      .with(on_finish: an_instance_of(MultiItemDeposit::DiscoverFilesFinishJob)
                         .and(having_attributes(arguments: [{ multi_item_deposit_action: }])))
    expect(multi_item_deposit_action.item_deposit_actions.size).to eq(2)
    multi_item_deposit_action.item_deposit_actions.each do |item_deposit_action|
      expect(MultiItemDeposit::DiscoverFilesJob).to have_been_enqueued.with(item_deposit_action:, effective_groups:)
    end
  end
end
