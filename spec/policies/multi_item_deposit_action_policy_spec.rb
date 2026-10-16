# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDepositActionPolicy, type: :policy do
  subject(:policy) { described_class.new(multi_item_deposit_action, user:) }

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner) }
  let(:owner) { create(:user) }

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
