# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemPolicy do
  subject(:policy) { described_class.new(user:) }

  describe '#new?' do
    subject { policy.apply(:new?) }

    let(:user) { create(:user, groups: [workgroup]) }
    let(:workgroup) { 'sdr:test-workgroup' }

    before do
      Current.effective_groups = user.groups
    end

    context 'when the user belongs to a workgroup with edit permission' do
      before do
        create(:permission, :edit, workgroup:)
      end

      it { is_expected.to be true }
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it { is_expected.to be false }
    end

    context 'when the effective groups differ from user groups' do
      before do
        Current.effective_groups = ['sdr:effective-group']
        create(:permission, :edit, workgroup: 'sdr:effective-group')
      end

      it { is_expected.to be true }
    end
  end
end
