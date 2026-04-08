# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::AdminPolicy do
  subject(:admin_policy) { described_class.new(cocina_object) }

  let(:cocina_object) { build(:admin_policy_with_metadata) }

  describe '#initialize' do
    context 'with a valid Cocina::Models::AdminPolicyWithMetadata' do
      it 'initializes with a Cocina::Models::AdminPolicyWithMetadata' do
        expect(admin_policy.external_identifier).to eq(cocina_object.externalIdentifier)
      end
    end

    context 'with an invalid object' do
      let(:cocina_object) { 'invalid' }

      it 'raises an error if initialized with an invalid object' do
        expect { admin_policy }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'type predicates' do
    it 'returns false for #dro?' do
      expect(admin_policy.dro?).to be false
    end

    it 'returns false for #collection?' do
      expect(admin_policy.collection?).to be false
    end

    it 'returns true for #admin_policy?' do
      expect(admin_policy.admin_policy?).to be true
    end
  end
end
