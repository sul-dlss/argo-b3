# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionPolicy do
  subject(:policy) { described_class.new(user:, record: nil) }

  describe '#index?' do
    context 'when an admin' do
      let(:user) { build_stubbed(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }

      it 'authorizes' do
        expect(policy.apply(:index?)).to be true
      end
    end

    context 'when a non-admin' do
      let(:user) { build_stubbed(:user, groups: ['sdr:user-group']) }

      it 'does not authorize' do
        expect(policy.apply(:index?)).to be false
      end
    end
  end
end
