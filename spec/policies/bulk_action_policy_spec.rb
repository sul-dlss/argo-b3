# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionPolicy do
  let(:user) { create(:user) }
  let!(:user_bulk_action) { create(:bulk_action, user:) }
  let!(:other_user_bulk_action) { create(:bulk_action) }

  describe 'relation scope' do
    subject(:scope) { described_class.new(user:).apply_scope(BulkAction.all, type: :active_record_relation) }

    context 'when an admin' do
      let(:user) { create(:user, :admin) }

      it 'returns the bulk actions of all users' do
        expect(scope).to contain_exactly(user_bulk_action, other_user_bulk_action)
      end
    end

    context 'when not an admin' do
      it 'returns only the bulk actions of the user' do
        expect(scope).to contain_exactly(user_bulk_action)
      end
    end
  end

  describe '#manage?' do
    it 'authorizes the user of the bulk action' do
      expect(described_class.new(user_bulk_action, user:).apply(:manage?)).to be true
    end

    it 'does not authorize another user' do
      expect(described_class.new(other_user_bulk_action, user:).apply(:manage?)).to be false
    end
  end

  describe '#cancel?' do
    it 'authorizes an admin' do
      admin = create(:user, :admin)

      expect(described_class.new(other_user_bulk_action, user: admin).apply(:cancel?)).to be true
    end

    it 'does not authorize the user of the bulk action' do
      expect(described_class.new(user_bulk_action, user:).apply(:cancel?)).to be false
    end
  end
end
