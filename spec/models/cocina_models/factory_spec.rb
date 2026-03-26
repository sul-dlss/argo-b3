# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::Factory do
  describe '.build' do
    context 'with a Cocina::Models::DROWithMetadata' do
      let(:cocina_object) { build(:dro_with_metadata) }

      it 'returns a CocinaModels::Dro' do
        result = described_class.build(cocina_object)

        expect(result).to be_a(CocinaModels::Dro)
        expect(result.external_identifier).to eq(cocina_object.externalIdentifier)
      end
    end

    context 'with a Cocina::Models::CollectionWithMetadata' do
      let(:cocina_object) { build(:collection_with_metadata) }

      it 'returns a CocinaModels::Collection' do
        result = described_class.build(cocina_object)

        expect(result).to be_a(CocinaModels::Collection)
        expect(result.external_identifier).to eq(cocina_object.externalIdentifier)
      end
    end

    context 'with an invalid object' do
      let(:cocina_object) { 'invalid' }

      it 'raises an ArgumentError' do
        expect { described_class.build(cocina_object) }
          .to raise_error(ArgumentError,
                          'Expected a Cocina::Models::DROWithMetadata or Cocina::Models::CollectionWithMetadata')
      end
    end
  end
end
