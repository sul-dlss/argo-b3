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
  end
end
