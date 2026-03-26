# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Collection do
  subject(:dro) { described_class.new(cocina_object) }

  let(:cocina_object) { build(:collection_with_metadata) }

  describe '#initialize' do
    context 'with a valid Cocina::Models::CollectionWithMetadata' do
      it 'initializes with a Cocina::Models::CollectionWithMetadata' do
        expect(dro.external_identifier).to eq(cocina_object.externalIdentifier)
        expect(dro.source_id).to eq(cocina_object.identification.sourceId)
      end
    end

    context 'with an invalid object' do
      let(:cocina_object) { 'invalid' }

      it 'raises an error if initialized with an invalid object' do
        expect { dro }.to raise_error(ArgumentError, 'Expected a Cocina::Models::CollectionWithMetadata')
      end
    end
  end

  describe '#save!' do
    let(:user_name) { 'test_user' }
    let(:description) { 'Changed source id' }

    before do
      allow(Sdr::Repository).to receive(:update)
    end

    context 'with valid and changed attributes' do
      let(:new_source_id) { 'changed:source-id' }

      before do
        dro.source_id = new_source_id
      end

      it 'saves the model successfully' do
        dro.save!(user_name:, description:)
        expect(Sdr::Repository).to have_received(:update) do |args|
          new_cocina_object = args[:cocina_object]
          expect(new_cocina_object).to be_a(Cocina::Models::CollectionWithMetadata)
          expect(new_cocina_object.lock).to eq(cocina_object.lock)
          expect(new_cocina_object.identification.sourceId).to eq(new_source_id)

          expect(args[:user_name]).to eq(user_name)
          expect(args[:description]).to eq(description)
        end
        expect(dro.changed?).to be false
      end
    end
  end
end
