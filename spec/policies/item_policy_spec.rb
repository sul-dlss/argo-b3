# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemPolicy do
  subject(:policy) { described_class.new(user:) }

  describe '#new?' do
    subject { policy.apply(:new?) }

    let(:user) { create(:user, groups: [workgroup]) }
    let(:workgroup) { 'sdr:test-workgroup' }

    context 'when the user belongs to a workgroup with edit permission' do
      before do
        create(:permission, :edit, workgroup:)
      end

      it { is_expected.to be true }
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it { is_expected.to be false }
    end
  end
end
