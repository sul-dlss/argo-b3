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
end
