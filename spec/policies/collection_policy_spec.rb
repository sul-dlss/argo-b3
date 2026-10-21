# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPolicy do
  let(:user) { create(:user, groups: [workgroup]) }
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:apo_druid) { 'druid:bc123df4567' }

  before { Current.effective_groups = user.groups }

  describe '#new?' do
    subject { described_class.new(user:).apply(:new?) }

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission' do
      before { create(:permission, :edit, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      before { create(:permission, :read_restricted, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be false }
    end
  end

  describe '#create?' do
    subject { described_class.new(apo_druid, user:).apply(:create?) }

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission for the selected APO' do
      before { create(:permission, :edit, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be true }
    end

    context 'when the user belongs to a workgroup with edit permission for a different APO' do
      before { create(:permission, :edit, workgroup:, target_druid: 'druid:xy987zw6543') }

      it { is_expected.to be false }
    end

    context 'when the user belongs to a workgroup with read permission for the selected APO' do
      before { create(:permission, :read_restricted, workgroup:, target_druid: apo_druid) }

      it { is_expected.to be false }
    end

    context 'when no APO is selected' do
      subject { described_class.new('', user:).apply(:create?) }

      context 'when the user belongs to a workgroup with edit permission' do
        before { create(:permission, :edit, workgroup:, target_druid: 'druid:xy987zw6543') }

        it { is_expected.to be true }
      end

      context 'when the user does not belong to a workgroup with edit permission' do
        it { is_expected.to be false }
      end
    end
  end
end
