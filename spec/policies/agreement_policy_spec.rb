# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgreementPolicy do
  subject(:policy) { described_class.new(user:) }

  let(:user) { create(:user, groups: [workgroup]) }
  let(:workgroup) { 'sdr:test-workgroup' }

  before { Current.effective_groups = user.groups }

  describe '#new?' do
    subject { policy.apply(:new?) }

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission for the ur APO' do
      before { create(:permission, :edit, workgroup:, target_druid: Settings.ur_apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission for a different APO' do
      before { create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567') }

      it { is_expected.to be false }
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it { is_expected.to be false }
    end
  end
end
