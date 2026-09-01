# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user:, record: nil) }

  let(:user) { build_stubbed(:user, groups: ['sdr:user-group']) }

  before do
    Current.effective_groups = nil
    Permission.permission_type_admin.delete_all
    create(:permission, :admin, workgroup: 'sdr:admin-group')
    described_class.admin_workgroups = nil
  end

  describe '#admin?' do
    context 'when user groups are not admin groups' do
      before do
        Current.effective_groups = ['sdr:user-group']
      end

      it 'returns false' do
        expect(policy.admin?).to be false
      end
    end

    context 'when effective groups include an admin group' do
      before do
        Current.effective_groups = ['sdr:admin-group']
      end

      it 'returns true' do
        expect(policy.admin?).to be true
      end
    end
  end

  describe '#current_groups' do
    context 'when Current.effective_groups is set' do
      before do
        Current.effective_groups = ['sdr:impersonated-group']
      end

      it 'returns effective groups' do
        expect(policy.current_groups).to eq(['sdr:impersonated-group'])
      end
    end

    context 'when Current.effective_groups is nil' do
      before do
        Current.effective_groups = nil
      end

      it 'falls back to user groups' do
        expect(policy.current_groups).to eq(['sdr:user-group'])
      end
    end
  end
end
