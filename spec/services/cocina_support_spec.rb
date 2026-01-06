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
end
