# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackedDeposit do
  describe '.track!' do
    let(:user) { create(:user) }

    it 'tracks the deposit of a version for the depositing user' do
      described_class.track!(druid: 'druid:bc123df4567', version: 2, user:)

      expect(described_class.sole).to have_attributes(druid: 'druid:bc123df4567', version: 2, user:)
    end

    context 'when the version is already tracked' do
      before { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2) }

      it 'tracks it for the user who deposited it last' do
        described_class.track!(druid: 'druid:bc123df4567', version: 2, user:)

        expect(described_class.sole.user).to eq(user)
      end
    end

    context 'when the version is tracked for a MID Item Deposit' do
      let(:item_deposit_action) { create(:item_deposit_action) }

      before { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, item_deposit_action:) }

      it 'keeps it part of the MID Item Deposit when deposited again' do
        described_class.track!(druid: 'druid:bc123df4567', version: 2, user:)

        expect(described_class.sole).to have_attributes(user:, item_deposit_action:)
      end
    end
  end

  describe 'retrying a MID Item Deposit' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, settled_at: 1.minute.ago) }
    let(:other_multi_item_deposit_action) { create(:multi_item_deposit_action, settled_at: 1.minute.ago) }

    before do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, staging_failed_at: 1.minute.ago,
                               process_errored_at: 1.minute.ago,
                               item_deposit_action: create(:item_deposit_action, multi_item_deposit_action:))
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 2, staging_failed_at: 1.minute.ago,
                               item_deposit_action: create(:item_deposit_action,
                                                           multi_item_deposit_action: other_multi_item_deposit_action))
    end

    it 'unsettles its Multi-Item Deposit when a Process is retried, leaving the error to the next poll' do
      described_class.process_retried!(druid: 'druid:bc123df4567')

      expect(described_class.find_by(druid: 'druid:bc123df4567').process_errored_at).to be_present
      expect(multi_item_deposit_action.reload.settled_at).to be_nil
      expect(other_multi_item_deposit_action.reload.settled_at).to be_present
    end

    it 'unsettles its Multi-Item Deposit when staging is retried' do
      described_class.staging_retried!(druid: 'druid:bc123df4567')

      expect(described_class.find_by(druid: 'druid:bc123df4567').staging_failed_at).to be_nil
      expect(multi_item_deposit_action.reload.settled_at).to be_nil
      expect(other_multi_item_deposit_action.reload.settled_at).to be_present
    end
  end

  describe 'a MID Item Deposit going In Error' do
    let(:tracked_deposit) { create(:tracked_deposit, item_deposit_action: create(:item_deposit_action)) }

    before { allow(DepositFailedNotifier).to receive(:with) }

    it 'records a staging failure without notifying' do
      expect(tracked_deposit.staging_failed!).to be false
      expect(tracked_deposit.staging_failed_at).to be_present
      expect(DepositFailedNotifier).not_to have_received(:with)
    end

    it 'records Processes in error without notifying' do
      tracked_deposit.process_errors_found!(workflow_errors: ['accessionWF:shelve:failed'], title: 'Maps')

      expect(tracked_deposit.process_errored_at).to be_present
      expect(DepositFailedNotifier).not_to have_received(:with)
    end
  end

  describe '.latest_for' do
    let!(:latest) { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 3) }

    before do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2)
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 4)
    end

    it "returns the Tracked Deposit of the object's latest tracked version" do
      expect(described_class.latest_for(druid: 'druid:bc123df4567')).to eq(latest)
    end
  end

  describe '.staging_retried!' do
    let!(:tracked_deposit) { create(:tracked_deposit, druid: 'druid:bc123df4567', staging_failed_at: 1.hour.ago) }
    let!(:other_tracked_deposit) do
      create(:tracked_deposit, druid: 'druid:cd234fg5678', staging_failed_at: 1.hour.ago)
    end

    it "clears the object's staging failures" do
      described_class.staging_retried!(druid: 'druid:bc123df4567')

      expect(tracked_deposit.reload.staging_failed_at).to be_nil
      expect(other_tracked_deposit.reload.staging_failed_at).to be_present
    end
  end

  describe '#staging_failed!' do
    let(:tracked_deposit) { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2) }

    before { allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) }

    it 'records the failure and notifies the depositing user' do
      freeze_time do
        tracked_deposit.staging_failed!(title: 'The Gettysburg Address', error_summary: 'Staging failed.')

        expect(tracked_deposit.reload.staging_failed_at).to eq(Time.current)
      end
      expect(Noticed::Event.sole).to be_a(DepositFailedNotifier)
      expect(Noticed::Event.sole.params).to include(druid: 'druid:bc123df4567', version: 2, cause: 'staging',
                                                    title: 'The Gettysburg Address',
                                                    error_summary: 'Staging failed.')
    end

    context 'when notifying fails' do
      before { allow(DepositFailedNotifier).to receive(:with).and_raise(ActiveRecord::ConnectionNotEstablished) }

      it 'clears the failure and raises' do
        expect { tracked_deposit.staging_failed!(title: 'A title', error_summary: 'Staging failed.') }
          .to raise_error(ActiveRecord::ConnectionNotEstablished)
        expect(tracked_deposit.reload.staging_failed_at).to be_nil
      end
    end
  end

  describe '#process_errors_found!' do
    let(:tracked_deposit) { create(:tracked_deposit, process_errored_at:) }
    let(:process_errored_at) { nil }
    let(:workflow_errors) { ['accessionWF:shelve:Error: shelving failed', 'ocrWF:ocr-create:Error: timed out'] }

    before { allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) }

    context 'when going from no Process in error to some' do
      it 'records the error and notifies the depositing user of every Process in error' do
        tracked_deposit.process_errors_found!(workflow_errors:, title: 'A title')

        expect(tracked_deposit.reload.process_errored_at).to be_present
        expect(Noticed::Event.sole.params)
          .to include(cause: 'process', error_summary: 'accessionWF:shelve:Error: shelving failed; ' \
                                                       'ocrWF:ocr-create:Error: timed out')
      end
    end

    context 'when Processes were already in error' do
      let(:process_errored_at) { 1.hour.ago }

      it 'does not notify again' do
        tracked_deposit.process_errors_found!(workflow_errors:, title: 'A title')

        expect(tracked_deposit.reload.process_errored_at).to be_within(1.second).of(process_errored_at)
        expect(Noticed::Event.count).to eq(0)
      end

      context 'when no Process is in error any longer (e.g., retried)' do
        it 'clears the error, so that the next error notifies' do
          tracked_deposit.process_errors_found!(workflow_errors: [], title: 'A title')

          expect(tracked_deposit.reload.process_errored_at).to be_nil
          expect(Noticed::Event.count).to eq(0)
        end
      end
    end
  end

  describe '#in_error_since?' do
    let(:time) { Time.zone.parse('2026-11-25 12:00') }
    let(:tracked_deposit) { build(:tracked_deposit, staging_failed_at: time - 1.second, process_errored_at: nil) }

    it 'is true only for a cause In Error since before the time' do
      expect(tracked_deposit.in_error_since?(cause: 'staging', time:)).to be true
      expect(tracked_deposit.in_error_since?(cause: 'staging', time: time - 1.minute)).to be false
      expect(tracked_deposit.in_error_since?(cause: 'process', time:)).to be false
    end
  end
end
