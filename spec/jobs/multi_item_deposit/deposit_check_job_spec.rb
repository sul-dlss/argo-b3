# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositCheckJob do
  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:other_druid) { 'druid:cd234fg5678' }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:user) { create(:user) }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, user:, step: 'deposit', initiating_deposit_state: 'initiating_depositing')
  end
  let!(:item_deposit_action) do
    create(:item_deposit_action, multi_item_deposit_action:, druid:, deposit_errors: ['Old error'],
                                 content: create(:content, :mutable, druid:, lock: 'abc123'))
  end
  let!(:other_item_deposit_action) do
    create(:item_deposit_action, multi_item_deposit_action:, druid: other_druid,
                                 content: create(:content, :mutable, druid: other_druid, lock: 'abc123'))
  end
  let(:effective_groups) { ['workgroup:depositors'] }
  let(:cocina_objects) do
    [druid, other_druid].index_with { |id| build(:dro_with_metadata, id:, admin_policy_id: apo_druid) }
  end
  let(:status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: false, openable?: true)
  end
  let(:other_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: true, closeable?: true)
  end
  let(:statuses) { { druid => status, other_druid => other_status } }

  # The test database has no queue tables, so a verifying double (which loads the schema) cannot be used.
  # The block enqueues to the test adapter.
  let(:batch_class) { double('SolidQueue::Batch') } # rubocop:disable RSpec/VerifiedDoubles

  before do
    create(:permission, :edit, workgroup: 'workgroup:depositors', target_druid: apo_druid)
    allow(Sdr::Repository).to receive(:find_all).and_return(cocina_objects)
    allow(Sdr::VersionService).to receive(:statuses).and_return(statuses)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
    stub_const('SolidQueue::Batch', batch_class)
    allow(batch_class).to receive(:enqueue).and_yield
  end

  def perform
    job.perform(multi_item_deposit_action:, effective_groups:)
    multi_item_deposit_action.reload
  end

  shared_examples 'completes with an error' do |error|
    it 'records the error, completes initiating the deposit, and notifies the user' do
      perform

      expect(item_deposit_action.reload.deposit_errors).to eq([error])
      expect(other_item_deposit_action.reload.deposit_errors).to eq([])
      expect(multi_item_deposit_action).to have_attributes(
        step: 'deposit', initiating_deposit_state: 'initiating_deposit_not_in_progress',
        initiating_deposit_completed_at: be_within(1.second).of(Time.current)
      )
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: include('Deposit check found errors'))
      expect(batch_class).not_to have_received(:enqueue)
    end
  end

  context 'when there are no errors' do
    it 'clears previous errors, submits the deposit, and enqueues a batch of deposit jobs' do
      perform

      expect(item_deposit_action.reload.deposit_errors).to eq([])
      expect(multi_item_deposit_action).to have_attributes(step: 'submitted',
                                                           initiating_deposit_state: 'initiating_depositing')
      expect(batch_class).to have_received(:enqueue)
        .with(on_finish: an_instance_of(MultiItemDeposit::DepositFinishJob)
                           .and(having_attributes(arguments: [{ multi_item_deposit_action: }])))
      expect(MultiItemDeposit::DepositJob).to have_been_enqueued.with(item_deposit_action:)
      expect(MultiItemDeposit::DepositJob).to have_been_enqueued.with(item_deposit_action: other_item_deposit_action)
      expect(Turbo::StreamsChannel).not_to have_received(:broadcast_append_to)
      expect(Sdr::Repository).to have_received(:find_all).with(druids: contain_exactly(druid, other_druid))
      expect(Sdr::VersionService).to have_received(:statuses).with(druids: contain_exactly(druid, other_druid))
    end
  end

  context 'when the object is not found' do
    let(:cocina_objects) { { other_druid => build(:dro_with_metadata, id: other_druid, admin_policy_id: apo_druid) } }

    it_behaves_like 'completes with an error', 'Object not found'
  end

  context 'when the version status is not found' do
    let(:statuses) { { other_druid => other_status } }

    it_behaves_like 'completes with an error', 'Object not found'
  end

  context 'when the user is not authorized to update the object' do
    let(:cocina_objects) do
      { druid => build(:dro_with_metadata, id: druid, admin_policy_id: 'druid:jk987mn6543'),
        other_druid => build(:dro_with_metadata, id: other_druid, admin_policy_id: apo_druid) }
    end

    it_behaves_like 'completes with an error', 'Not authorized to update'
  end

  context 'when the object has changed since discovery' do
    before do
      item_deposit_action.content.update!(lock: 'def456')
    end

    it_behaves_like 'completes with an error', 'Object changed since discovery; re-run Discover'
  end

  context 'when the Content no longer exists' do
    before do
      item_deposit_action.update!(content: nil)
    end

    it_behaves_like 'completes with an error', 'Object changed since discovery; re-run Discover'
  end

  context 'when the object is closed and cannot be opened' do
    let(:status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: false, openable?: false)
    end

    it_behaves_like 'completes with an error', 'A new version cannot be opened for this object'
  end

  context 'when the object is open and cannot be closed' do
    let(:status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: true, closeable?: false)
    end

    it_behaves_like 'completes with an error', 'The open version cannot be closed for this object'
  end

  context 'when an unexpected error occurs' do
    let(:error) { Sdr::VersionService::Error.new('Retrieving version statuses failed') }

    before do
      allow(Sdr::VersionService).to receive(:statuses).and_raise(error)
      allow(Honeybadger).to receive(:notify)
    end

    it 'records an error on every Item Deposit, notifies Honeybadger, and completes initiating the deposit' do
      perform

      unexpected_error = 'An unexpected error occurred while checking the deposit. Contact SDR support for assistance.'
      expect(item_deposit_action.reload.deposit_errors).to eq([unexpected_error])
      expect(other_item_deposit_action.reload.deposit_errors).to eq([unexpected_error])
      expect(multi_item_deposit_action).to have_attributes(
        step: 'deposit', initiating_deposit_state: 'initiating_deposit_not_in_progress'
      )
      expect(Honeybadger).to have_received(:notify).with(error)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: include('Deposit check found errors'))
    end
  end

  context 'when enqueuing the deposit jobs fails' do
    before do
      allow(batch_class).to receive(:enqueue).and_raise(StandardError, 'Queue unavailable')
      allow(Honeybadger).to receive(:notify)
    end

    it 'returns the user to the deposit step' do
      expect(perform).to have_attributes(step: 'deposit',
                                         initiating_deposit_state: 'initiating_deposit_not_in_progress')
    end
  end
end
