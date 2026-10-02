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

  describe '#lock' do
    context 'when the object is found' do
      let(:object_client) { instance_double(Dor::Services::Client::Object, lock: 'abc123') }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'returns the lock' do
        expect(described_class.lock(druid:)).to eq('abc123')
        expect(Dor::Services::Client).to have_received(:object).with(druid)
      end
    end

    context 'when the object is not found' do
      before do
        allow(Dor::Services::Client).to receive(:object).and_raise(Dor::Services::Client::NotFoundResponse)
      end

      it 'raises' do
        expect { described_class.lock(druid:) }.to raise_error(Sdr::Repository::NotFoundResponse)
      end
    end
  end

  describe '#find_solr' do
    context 'when the object is found' do
      let(:solr_doc) { { 'id' => druid } }
      let(:object_client) { instance_double(Dor::Services::Client::Object, solr: solr_doc) }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'returns the Solr document' do
        expect(described_class.find_solr(druid:)).to eq(solr_doc)
        expect(Dor::Services::Client).to have_received(:object).with(druid)
        expect(object_client).to have_received(:solr).with(validate: false)
      end
    end

    context 'when the object is not found' do
      before do
        allow(Dor::Services::Client).to receive(:object).and_raise(Dor::Services::Client::NotFoundResponse)
      end

      it 'raises' do
        expect { described_class.find_solr(druid:) }.to raise_error(Sdr::Repository::NotFoundResponse)
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
    let(:request_cocina_object) { instance_double(Cocina::Models::RequestDRO) }
    let(:registered_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }

    let(:objects_client) { instance_double(Dor::Services::Client::Objects, register: registered_cocina_object) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, workflow: workflow_client, administrative_tags: administrative_tags_client) }
    let(:administrative_tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, create: nil) }
    let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true) }

    let(:workflow_name) { 'goobiWF' }
    let(:tags) { %w[tag1 tag2] }

    before do
      allow(Dor::Services::Client).to receive_messages(objects: objects_client, object: object_client)
    end

    context 'when successful' do
      it 'registers with SDR, creates tags, and creates initial workflow' do
        expect(described_class.register(request_cocina_object:, user_name:, workflow_name:,
                                        tags:)).to eq(registered_cocina_object)

        expect(objects_client).to have_received(:register).with(params: request_cocina_object, user_name:)
        expect(Dor::Services::Client).to have_received(:object).with(druid)
        expect(administrative_tags_client).to have_received(:create).with(tags:)
        expect(object_client).to have_received(:workflow).with('goobiWF')
        expect(workflow_client).to have_received(:create).with(version: '1')
      end
    end

    context 'when no workflow_name is given' do
      it 'registers with SDR and creates registrationWF' do
        expect(described_class.register(request_cocina_object:, user_name:)).to eq(registered_cocina_object)

        expect(objects_client).to have_received(:register).with(params: request_cocina_object, user_name:)
        expect(object_client).to have_received(:workflow).with('registrationWF')
        expect(workflow_client).to have_received(:create).with(version: '1')
      end
    end

    context 'when registration fails' do
      before do
        allow(objects_client).to receive(:register).and_raise(Dor::Services::Client::Error, 'Failed to register')
      end

      it 'raises' do
        expect { described_class.register(request_cocina_object:, user_name:, workflow_name:) }.to raise_error(Sdr::Repository::Error)
      end
    end
  end

  describe '.source_id_exists?' do
    let(:source_id) { 'sul:1234' }
    let(:objects_client) { instance_double(Dor::Services::Client::Objects, find: true) }

    before do
      allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
    end

    context 'when an object with the source_id exists' do
      it 'returns true' do
        expect(described_class.source_id_exists?(source_id:)).to be true
        expect(objects_client).to have_received(:find).with(source_id:)
      end
    end

    context 'when no object with the source_id exists' do
      before { allow(objects_client).to receive(:find).and_raise(Dor::Services::Client::NotFoundResponse) }

      it 'returns false' do
        expect(described_class.source_id_exists?(source_id:)).to be false
      end
    end
  end

  describe '#accession' do
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
    let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true) }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object, version: version_client, workflow: workflow_client)
    end
    let(:type) { Cocina::Models::ObjectType.image }
    let(:cocina_object) { build(:dro, id: druid, type:, version: 2).new(structural:) }
    let(:structural) do
      {
        contains: [
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: 'bc123df4567_1',
            label: 'Fileset 1',
            version: 2,
            structural: { contains: files }
          }
        ]
      }
    end
    let(:files) do
      [
        {
          type: Cocina::Models::ObjectType.file,
          externalIdentifier: 'https://cocina.sul.stanford.edu/file/bc123df4567-1/image1.tif',
          label: 'image1.tif',
          filename: 'image1.tif',
          version: 2
        }
      ]
    end

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    context 'when the object has files' do
      it 'creates an assemblyWF' do
        described_class.accession(cocina_object:, user_name:)

        expect(object_client).to have_received(:workflow).with('assemblyWF')
        expect(workflow_client).to have_received(:create).with(version: 2, lane_id: 'high', context: nil)
        expect(version_client).not_to have_received(:close)
      end
    end

    context 'when the object is geo and has files' do
      let(:type) { Cocina::Models::ObjectType.geo }

      it 'creates a gisAssemblyWF' do
        described_class.accession(cocina_object:, user_name:)

        expect(object_client).to have_received(:workflow).with('gisAssemblyWF')
        expect(workflow_client).to have_received(:create).with(version: 2, lane_id: 'high', context: nil)
      end
    end

    context 'when the object has file sets without files' do
      let(:files) { [] }

      it 'closes the version to initiate accessioning' do
        described_class.accession(cocina_object:, user_name:)

        expect(version_client).to have_received(:close).with(user_name:, lane_id: 'high')
        expect(object_client).not_to have_received(:workflow)
      end
    end

    context 'when the object has no file sets' do
      let(:structural) { {} }

      it 'closes the version to initiate accessioning' do
        described_class.accession(cocina_object:, user_name:)

        expect(version_client).to have_received(:close).with(user_name:, lane_id: 'high')
      end
    end

    context 'when a lane_id is given' do
      it 'creates the workflow with the given lane_id' do
        described_class.accession(cocina_object:, user_name:, lane_id: 'low')

        expect(workflow_client).to have_received(:create).with(version: 2, lane_id: 'low', context: nil)
      end
    end

    context 'when accessioning fails' do
      before do
        allow(workflow_client).to receive(:create).and_raise(Dor::Services::Client::Error, 'Failed to create')
      end

      it 'raises' do
        expect { described_class.accession(cocina_object:, user_name:) }.to raise_error(Sdr::Repository::Error)
      end
    end
  end

  describe '#publish' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, publish: 'https://sdr.stanford.edu/job/1') }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    context 'when no lane_id is given' do
      it 'publishes without a lane_id' do
        described_class.publish(druid:)

        expect(object_client).to have_received(:publish).with(lane_id: nil)
      end
    end

    context 'when a lane_id is given' do
      it 'publishes with the given lane_id' do
        described_class.publish(druid:, lane_id: 'low')

        expect(object_client).to have_received(:publish).with(lane_id: 'low')
      end
    end

    context 'when publishing fails' do
      before do
        allow(object_client).to receive(:publish).and_raise(Dor::Services::Client::Error, 'Failed to publish')
      end

      it 'raises' do
        expect { described_class.publish(druid:) }.to raise_error(Sdr::Repository::Error)
      end
    end
  end

  describe '#create_release_tag' do
    let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, create: true) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, release_tags: release_tags_client) }
    let(:release_target) { 'Searchworks' }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    context 'when successful' do
      it 'creates a release tag' do
        described_class.create_release_tag(druid:, user_name:, release_target:, release: true)

        expect(Dor::Services::Client).to have_received(:object).with(druid)
        expect(release_tags_client).to have_received(:create) do |tag:, lane_id:|
          expect(tag.who).to eq(user_name)
          expect(tag.what).to eq('self')
          expect(tag.to).to eq(release_target)
          expect(tag.release).to be(true)
          expect(lane_id).to eq('high')
        end
      end
    end

    context 'when release_what and lane_id are given' do
      it 'creates a release tag with the given release_what and lane_id' do
        described_class.create_release_tag(druid:, user_name:, release_target:, release: false,
                                           release_what: 'collection', lane_id: 'low')

        expect(release_tags_client).to have_received(:create) do |tag:, lane_id:|
          expect(tag.what).to eq('collection')
          expect(tag.release).to be(false)
          expect(lane_id).to eq('low')
        end
      end
    end

    context 'when release_target is nil' do
      it 'creates a release tag with a blank to' do
        described_class.create_release_tag(druid:, user_name:, release_target: nil, release: false)

        expect(release_tags_client).to have_received(:create) do |tag:, lane_id:|
          expect(tag.to).to eq('')
          expect(lane_id).to eq('high')
        end
      end
    end

    context 'when creating the release tag fails' do
      before do
        allow(release_tags_client).to receive(:create).and_raise(Dor::Services::Client::Error, 'Failed to create tag')
      end

      it 'raises' do
        expect do
          described_class.create_release_tag(druid:, user_name:, release_target:, release: true)
        end.to raise_error(Sdr::Repository::Error)
      end
    end
  end

  describe '#release_tags' do
    context 'when the object is found' do
      let(:release_tags) { [instance_double(Dor::Services::Client::ReleaseTag)] }
      let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: release_tags) }
      let(:object_client) { instance_double(Dor::Services::Client::Object, release_tags: release_tags_client) }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'returns the release tags' do
        expect(described_class.release_tags(druid:)).to eq(release_tags)
        expect(Dor::Services::Client).to have_received(:object).with(druid)
        expect(release_tags_client).to have_received(:list).with(public: true)
      end
    end

    context 'when the object is not found' do
      before do
        allow(Dor::Services::Client).to receive(:object).and_raise(Dor::Services::Client::NotFoundResponse)
      end

      it 'raises' do
        expect { described_class.release_tags(druid:) }.to raise_error(Sdr::Repository::NotFoundResponse)
      end
    end
  end
end
