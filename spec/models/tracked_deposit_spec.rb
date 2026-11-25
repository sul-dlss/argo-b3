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

      before do
        create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, item_deposit_action:, in_error: true)
      end

      it 'keeps it part of the MID Item Deposit when deposited again, no longer in error' do
        described_class.track!(druid: 'druid:bc123df4567', version: 2, user:)

        expect(described_class.sole).to have_attributes(user:, item_deposit_action:, in_error: false)
      end
    end
  end

  describe '.retried!' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, settled_at: 1.minute.ago) }
    let(:other_multi_item_deposit_action) { create(:multi_item_deposit_action, settled_at: 1.minute.ago) }

    before do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, in_error: true,
                               item_deposit_action: create(:item_deposit_action, multi_item_deposit_action:))
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 2, in_error: true,
                               item_deposit_action: create(:item_deposit_action,
                                                           multi_item_deposit_action: other_multi_item_deposit_action))
    end

    it 'takes the druid out of error and unsettles its Multi-Item Deposit' do
      described_class.retried!(druid: 'druid:bc123df4567')

      expect(described_class.find_by(druid: 'druid:bc123df4567')).to have_attributes(in_error: false,
                                                                                     recently_retried?: true)
      expect(described_class.find_by(druid: 'druid:cd234fg5678').in_error).to be true
      expect(multi_item_deposit_action.reload.settled_at).to be_nil
      expect(other_multi_item_deposit_action.reload.settled_at).to be_present
    end
  end
end
