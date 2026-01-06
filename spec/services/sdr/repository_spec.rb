# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::Repository do
  let(:druid) { 'druid:bc123df4567' }
  let(:user_name) { 'test_user' }

  describe '#find' do
    context 'when the object is found' do
      let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }

      let(:cocina_object) { instance_double(Cocina::Models::DRO) }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'returns the object' do
        expect(described_class.find(druid:)).to eq(cocina_object)
        expect(Dor::Services::Client).to have_received(:object).with(druid)
      end
    end

    context 'when the object is not found' do
      before do
        allow(Dor::Services::Client).to receive(:object).and_raise(Dor::Services::Client::NotFoundResponse)
      end

      it 'raises' do
        expect { described_class.find(druid:) }.to raise_error(Sdr::Repository::NotFoundResponse)
      end
    end
  end

  describe '#update' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }

    let(:updated_cocina_object) { instance_double(Cocina::Models::DRO) }

    let(:object_client) { instance_double(Dor::Services::Client::Object, update: updated_cocina_object) }
    let(:description) { 'stuff changed' }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    context 'when successful' do
      it 'updates with SDR' do
        expect(described_class.update(cocina_object:, description:, user_name:)).to eq(updated_cocina_object)

        expect(object_client).to have_received(:update).with(params: cocina_object,
                                                             user_name:,
                                                             description:)
      end
    end

    context 'when update fails' do
      let(:objects_client) { instance_double(Dor::Services::Client::Objects) }

      before do
        allow(object_client).to receive(:update).and_raise(Dor::Services::Client::Error, 'Failed to update')
      end

      it 'raises' do
        expect { described_class.update(cocina_object:, user_name:) }.to raise_error(Sdr::Repository::Error)
      end
    end
  end

  describe '#register' do
    let(:cocina_object) { instance_double(Cocina::Models::RequestDRO) }
    let(:registered_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }

    let(:objects_client) { instance_double(Dor::Services::Client::Objects, register: registered_cocina_object) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, workflow: workflow_client, administrative_tags: administrative_tags_client) }
    let(:administrative_tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, create: nil) }
    let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true) }

    let(:workflow_name) { 'registrationWF' }
    let(:tags) { %w[tag1 tag2] }

    before do
      allow(Dor::Services::Client).to receive_messages(objects: objects_client, object: object_client)
    end

    context 'when successful' do
      it 'registers with SDR, creates tags, and creates initial workflow' do
        expect(described_class.register(cocina_object:, user_name:, workflow_name:,
                                        tags:)).to eq(registered_cocina_object)

        expect(objects_client).to have_received(:register).with(params: cocina_object, user_name:)
        expect(Dor::Services::Client).to have_received(:object).with(druid)
        expect(administrative_tags_client).to have_received(:create).with(tags:)
        expect(workflow_client).to have_received(:create).with(version: '1')
      end
    end

    context 'when registration fails' do
      before do
        allow(objects_client).to receive(:register).and_raise(Dor::Services::Client::Error, 'Failed to register')
      end

      it 'raises' do
        expect { described_class.register(cocina_object:, user_name:, workflow_name:) }.to raise_error(Sdr::Repository::Error)
      end
    end
  end
end
