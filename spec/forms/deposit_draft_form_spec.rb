# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DepositDraftForm do
  describe '.for_status' do
    let(:version_service) { version_service_double(version_description: 'Fixed the title') }

    it 'prefills the open version description and the lock' do
      form = described_class.for_status(lock: 'abc123', version_service:)

      expect(form.version_description).to eq('Fixed the title')
      expect(form.lock).to eq('abc123')
    end
  end

  describe '.stale_warning' do
    it 'returns the warning of the edit form for the object type' do
      expect(described_class.stale_warning(build(:dro_with_metadata)))
        .to eq('This item was changed since you opened it. Review the current values and make your changes again.')
      expect(described_class.stale_warning(build(:collection_with_metadata)))
        .to eq('This collection was changed since you opened it. ' \
               'Review the current values and make your changes again.')
      expect(described_class.stale_warning(build(:admin_policy_with_metadata)))
        .to eq('This APO was changed since you opened it. Review the current values and make your changes again.')
      expect(described_class.stale_warning(build(:dro_with_metadata, type: Cocina::Models::ObjectType.agreement)))
        .to eq('This agreement was changed since you opened it. ' \
               'Review the current values and make your changes again.')
    end
  end

  describe '#stale?' do
    # The factory's lock is 'abc123'.
    let(:cocina_object) { build(:dro_with_metadata) }

    it 'is stale when the lock differs or is missing' do
      expect(described_class.new(lock: 'abc123')).not_to be_stale(cocina_object)
      expect(described_class.new(lock: 'def456')).to be_stale(cocina_object)
      expect(described_class.new).to be_stale(cocina_object)
    end
  end
end
