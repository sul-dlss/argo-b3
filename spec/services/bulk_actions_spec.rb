# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions do
  describe '.all' do
    subject(:configs) { described_class.all }

    it 'returns only bulk action configs' do
      expect(configs).to all(be_a(BulkActions::Config))
    end

    it 'includes the bulk action types' do
      expect(configs.map(&:action_type)).to include('ADD_WORKFLOW', 'REDEPOSIT', 'REGISTER_CSV')
    end
  end

  describe '.in_section' do
    it 'returns the configs of the section in definition order' do
      labels = described_class.in_section(:perform_actions).map(&:label)

      expect(labels).to eq(['Manage release', 'Republish', 'Reindex'])
    end
  end

  describe BulkActions::Config do
    describe '#cancellable?' do
      it 'returns true by default' do
        expect(described_class.new.cancellable?).to be true
      end

      it 'returns false when cancellable is false' do
        expect(described_class.new(cancellable: false).cancellable?).to be false
      end
    end
  end
end
