# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaSupport do
  describe '#validate' do
    subject(:result) { described_class.validate(cocina_object, **params) }

    context 'when the cocina object is valid' do
      let(:cocina_object) do
        build(:dro)
      end

      let(:params) { { type: Cocina::Models::ObjectType.book } }

      it 'returns a Success monad' do
        expect(result).to be_success
      end
    end

    context 'when the cocina object is invalid' do
      let(:cocina_object) do
        build(:dro)
      end

      let(:params) { { type: 'InvalidType' } }

      it 'returns a Failure monad with the validation error message' do
        expect(result).to be_failure
        expect(result.failure).to include("Unknown type: 'InvalidType'")
      end
    end
  end

  describe '#build_from_cocina_hash' do
    subject(:cocina_object) { described_class.build_from_cocina_hash(cocina_hash) }

    let(:cocina_with_metadata) { build(:dro_with_metadata) }
    let(:cocina_hash) { cocina_with_metadata.to_h }

    it 'builds a cocina model with metadata' do
      expect(cocina_object).to be_a(Cocina::Models::DROWithMetadata)
      expect(cocina_object.externalIdentifier).to eq(cocina_with_metadata.externalIdentifier)
      expect(cocina_object.lock).to eq(cocina_with_metadata.lock)
      expect(cocina_object.created).to eq(cocina_with_metadata.created)
      expect(cocina_object.modified).to eq(cocina_with_metadata.modified)
    end

    it 'removes the metadata keys from the given hash' do
      expect { cocina_object }.to change { cocina_hash.key?(:lock) }.from(true).to(false)
      expect(cocina_hash).not_to have_key(:created)
      expect(cocina_hash).not_to have_key(:modified)
    end
  end

  describe '.agreement?, .virtual_object?, and .item?' do
    let(:item) { build(:dro, type: Cocina::Models::ObjectType.book) }
    let(:agreement) { build(:dro, type: Cocina::Models::ObjectType.agreement) }
    let(:virtual_object) do
      build(:dro, type: Cocina::Models::ObjectType.image)
        .new(structural: { hasMemberOrders: [{ members: ['druid:bc123df4567'] }] })
    end
    let(:empty_member_orders) do
      build(:dro, type: Cocina::Models::ObjectType.book)
        .new(structural: { hasMemberOrders: [{ viewingDirection: 'left-to-right' }] })
    end
    let(:collection) { build(:collection) }
    let(:admin_policy) { build(:admin_policy) }

    it 'identifies an Item' do
      expect(described_class.item?(item)).to be true
      expect(described_class.item?(empty_member_orders)).to be true
      expect(described_class.agreement?(item)).to be false
      expect(described_class.virtual_object?(item)).to be false
    end

    it 'identifies an Agreement' do
      expect(described_class.agreement?(agreement)).to be true
      expect(described_class.item?(agreement)).to be false
    end

    it 'identifies a Virtual Object' do
      expect(described_class.virtual_object?(virtual_object)).to be true
      expect(described_class.item?(virtual_object)).to be false
    end

    it 'does not identify a Collection or APO as an Item' do
      expect(described_class.item?(collection)).to be false
      expect(described_class.item?(admin_policy)).to be false
      expect(described_class.virtual_object?(collection)).to be false
    end
  end
end
