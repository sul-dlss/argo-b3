# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDepositActionPolicy, type: :policy do
  subject(:policy) { described_class.new(multi_item_deposit_action, user:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner) }
  let(:owner) { create(:user) }

  describe 'relation scope' do
    subject(:scope) do
      described_class.new(user:).apply_scope(MultiItemDepositAction.all, type: :active_record_relation)
    end

    let!(:user_multi_item_deposit_action) { create(:multi_item_deposit_action, user:) }
    let!(:other_user_multi_item_deposit_action) { create(:multi_item_deposit_action) }

    context 'when an admin' do
      let(:user) { create(:user, :admin) }

      it 'returns the Multi-Item Deposits of all users' do
        expect(scope).to contain_exactly(user_multi_item_deposit_action, other_user_multi_item_deposit_action)
      end
    end

    context 'when not an admin' do
      let(:user) { create(:user) }

      it 'returns only the Multi-Item Deposits of the user' do
        expect(scope).to contain_exactly(user_multi_item_deposit_action)
      end
    end
  end

  describe '#edit?' do
    subject { policy.apply(:edit?) }

    context 'when the multi-item deposit action belongs to the user' do
      let(:user) { owner }

      it { is_expected.to be true }
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:user) { create(:user) }

      it { is_expected.to be false }
    end
  end
end
