# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::PresenterFactory do
  describe '.build' do
    context 'with a CocinaModels::Dro' do
      let(:cocina_object) { build(:dro_with_metadata) }
      let(:cocina_model) { CocinaModels::Factory.build(cocina_object) }

      it 'returns a CocinaModels::DroPresenter' do
        result = described_class.build(cocina_model)

        expect(result).to be_a(CocinaModels::DroPresenter)
        expect(result.external_identifier).to eq(cocina_object.externalIdentifier)
      end
    end

    context 'with a CocinaModels::Collection' do
      let(:cocina_object) { build(:collection_with_metadata) }
      let(:cocina_model) { CocinaModels::Factory.build(cocina_object) }

      it 'returns a CocinaModels::CollectionPresenter' do
        result = described_class.build(cocina_model)

        expect(result).to be_a(CocinaModels::CollectionPresenter)
        expect(result.external_identifier).to eq(cocina_object.externalIdentifier)
      end
    end

    context 'with a CocinaModels::AdminPolicy' do
      let(:cocina_object) { build(:admin_policy_with_metadata) }
      let(:cocina_model) { CocinaModels::Factory.build(cocina_object) }

      it 'returns a CocinaModels::AdminPolicyPresenter' do
        result = described_class.build(cocina_model)

        expect(result).to be_a(CocinaModels::AdminPolicyPresenter)
        expect(result.external_identifier).to eq(cocina_object.externalIdentifier)
      end
    end

    context 'with an invalid object' do
      let(:cocina_model) { 'invalid' }

      it 'raises an ArgumentError' do
        expect { described_class.build(cocina_model) }
          .to raise_error(ArgumentError, 'Unexpected cocina object type')
      end
    end
  end

  describe '.build_from_cocina_object' do
    let(:cocina_object) { build(:dro_with_metadata) }

    it 'builds a presenter from a cocina object' do
      result = described_class.build_from_cocina_object(cocina_object)

      expect(result).to be_a(CocinaModels::DroPresenter)
      expect(result.external_identifier).to eq(cocina_object.externalIdentifier)
    end
  end

  describe '.build_from_cocina_hash' do
    let(:cocina_object_with_metadata) { build(:dro_with_metadata) }
    let(:cocina_hash) { cocina_object_with_metadata.to_h.deep_symbolize_keys }

    it 'builds a presenter from a cocina hash with metadata' do
      result = described_class.build_from_cocina_hash(cocina_hash)

      expect(result).to be_a(CocinaModels::DroPresenter)
      expect(result.external_identifier).to eq(cocina_object_with_metadata.externalIdentifier)
    end
  end
end
