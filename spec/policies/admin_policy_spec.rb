# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPolicy do
  subject(:policy) { described_class.new(user:, record: nil) }

  let(:user) { build_stubbed(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }

  describe 'aliases' do
    it 'resolves manage_permissions? to admin?' do
      expect(policy.resolve_rule(:manage_permissions?)).to eq(:admin?)
    end

    it 'resolves groups? to admin?' do
      expect(policy.resolve_rule(:groups?)).to eq(:admin?)
    end

    it 'resolves update_impersonation? to impersonate?' do
      expect(policy.resolve_rule(:update_impersonation?)).to eq(:impersonate?)
    end
  end

  describe '#impersonate?' do
    context 'when an admin is not impersonating' do
      it 'authorizes' do
        expect(policy.apply(:impersonate?)).to be true
      end
    end

    context 'when an admin is impersonating' do
      before do
        Current.impersonated_groups = [AuthenticationHelpers::ADMIN_GROUP]
        Current.effective_groups = [AuthenticationHelpers::ADMIN_GROUP]
      end

      it 'does not authorize' do
        expect(policy.apply(:impersonate?)).to be false
      end
    end

    context 'when a non-admin is not impersonating' do
      let(:user) { build_stubbed(:user, groups: ['sdr:user-group']) }

      it 'does not authorize' do
        expect(policy.apply(:impersonate?)).to be false
      end
    end
  end

  describe '#stop_impersonating?' do
    context 'when an admin is not impersonating' do
      it 'does not authorize' do
        expect(policy.apply(:stop_impersonating?)).to be false
      end
    end

    context 'when impersonating' do
      before do
        Current.impersonated_groups = ['sdr:user-group']
        Current.effective_groups = ['sdr:user-group']
      end

      it 'authorizes' do
        expect(policy.apply(:stop_impersonating?)).to be true
      end
    end
  end
end
