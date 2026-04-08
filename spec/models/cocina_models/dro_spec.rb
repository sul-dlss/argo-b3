# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaModels::Dro do
  include ActiveModel::Lint::Tests
  include ActiveSupport::Testing::Assertions

  subject(:dro) { described_class.new(cocina_object) }

  let(:cocina_object) { build(:dro_with_metadata) }

  describe '#initialize' do
    context 'with a valid Cocina::Models::DROWithMetadata' do
      it 'initializes with a Cocina::Models::DROWithMetadata' do
        expect(dro.external_identifier).to eq(cocina_object.externalIdentifier)
        expect(dro.source_id).to eq(cocina_object.identification.sourceId)
      end
    end

    context 'with an invalid object' do
      let(:cocina_object) { 'invalid' }

      it 'raises an error if initialized with an invalid object' do
        expect { dro }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#update' do
    let(:new_source_id) { 'new-source-id' }
    let(:attributes) { { source_id: new_source_id } }

    it 'updates the attributes of the model' do
      dro.update(attributes)
      expect(dro.source_id).to eq(new_source_id)
    end

    context 'when updating external_identifier' do
      let(:new_external_identifier) { 'new-external-identifier' }
      let(:attributes) { { external_identifier: new_external_identifier } }

      it 'does not allow updating external_identifier' do
        expect { dro.update(attributes) }.to raise_error(ActiveModel::UnknownAttributeError)
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
          expect(new_cocina_object).to be_a(Cocina::Models::DROWithMetadata)
          expect(new_cocina_object.lock).to eq(cocina_object.lock)
          expect(new_cocina_object.identification.sourceId).to eq(new_source_id)

          expect(args[:user_name]).to eq(user_name)
          expect(args[:description]).to eq(description)
        end
        expect(dro.changed?).to be false
      end
    end

    context 'with invalid attributes' do
      before do
        dro.source_id = 'invalid-source-id'
      end

      it 'raises a validation error' do
        expect { dro.save!(user_name:, description:) }.to raise_error(ActiveModel::ValidationError)
      end
    end

    context 'when no attributes have changed' do
      it 'does not attempt to save' do
        dro.save!(user_name:, description:)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end

  describe 'change tracking' do
    it 'tracks changes to attributes' do
      expect(dro.changed?).to be false
      expect(dro.source_id_changed?).to be false
      dro.source_id = 'changed-source-id'
      expect(dro.changed?).to be true
      expect(dro.source_id_changed?).to be true
    end
  end

  # ActiveModel::Lint::Tests expects this method name
  def model
    dro
  end

  # Run all lint tests as RSpec examples
  ActiveModel::Lint::Tests.instance_methods.grep(/^test/).each do |method_name|
    it method_name.to_s do # rubocop:disable RSpec/NoExpectationExample
      send(method_name)
    end
  end
end
