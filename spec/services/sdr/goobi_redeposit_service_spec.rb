# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::GoobiRedepositService do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workflow: workflow_client,
                                                   workflows: Dor::Services::Response::Workflows.new(xml: Nokogiri::XML(workflows_xml)))
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, status: version_status) }
  let(:version_status) { instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: open, version: 2) }
  let(:open) { false }
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: nil) }
  let(:workflows_xml) do
    <<~XML
      <workflows objectId="#{druid}">
        <workflow objectId="#{druid}" id="accessionWF">
          <process version="1" status="completed" name="start-accession"/>
          <process version="1" status="skipped" name="shelve"/>
        </workflow>
      </workflows>
    XML
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe '.goobi_content_type?' do
    it 'is true for image and book Items' do
      image = build(:dro, id: druid, type: Cocina::Models::ObjectType.image)
      book = build(:dro, id: druid, type: Cocina::Models::ObjectType.book)

      expect(described_class.goobi_content_type?(image)).to be true
      expect(described_class.goobi_content_type?(book)).to be true
    end

    it 'is false for other content types and object types' do
      map = build(:dro, id: druid, type: Cocina::Models::ObjectType.map)

      expect(described_class.goobi_content_type?(map)).to be false
      expect(described_class.goobi_content_type?(build(:collection, id: druid))).to be false
    end

    it 'is false for an image Virtual Object' do
      virtual_object = build(:dro, id: druid, type: Cocina::Models::ObjectType.image).new(
        structural: { hasMemberOrders: [{ members: ['druid:hj456km7890'] }] }
      )

      expect(described_class.goobi_content_type?(virtual_object)).to be false
    end
  end

  describe '.redepositable?' do
    subject(:redepositable) { described_class.redepositable?(version_service: Sdr::VersionService.new(druid:)) }

    context 'when every workflow is complete' do
      it { is_expected.to be true }
    end

    context 'when a workflow has a process that is not complete' do
      let(:workflows_xml) do
        <<~XML
          <workflows objectId="#{druid}">
            <workflow objectId="#{druid}" id="accessionWF">
              <process version="1" status="completed" name="start-accession"/>
              <process version="1" status="error" name="shelve"/>
            </workflow>
          </workflows>
        XML
      end

      it { is_expected.to be false }
    end

    context 'when goobiWF was started for the open version' do
      let(:open) { true }
      let(:workflows_xml) do
        <<~XML
          <workflows objectId="#{druid}">
            <workflow objectId="#{druid}" id="goobiWF">
              <process version="2" status="completed" name="start"/>
              <process version="2" status="completed" name="goobi-notify"/>
            </workflow>
          </workflows>
        XML
      end

      it 'is not redepositable, even once goobiWF is complete' do
        expect(redepositable).to be false
      end
    end

    context 'when goobiWF was started for an earlier version' do
      let(:open) { true }
      let(:workflows_xml) do
        <<~XML
          <workflows objectId="#{druid}">
            <workflow objectId="#{druid}" id="goobiWF">
              <process version="1" status="completed" name="start"/>
              <process version="1" status="completed" name="goobi-notify"/>
            </workflow>
          </workflows>
        XML
      end

      it { is_expected.to be true }
    end
  end

  describe '.call' do
    subject(:call) { described_class.call(cocina_object:, user_name: 'jdoe') }

    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book, version: 2) }

    context 'when the version is closed' do
      let(:open) { false }

      before do
        allow(version_client).to receive(:open).and_return(cocina_object.new(version: 3))
      end

      it 'opens a version and starts goobiWF for it' do
        call

        expect(Dor::Services::Client).to have_received(:object).with(druid).at_least(:once)
        expect(version_client).to have_received(:open).with(description: 'Redeposit with Goobi',
                                                            opening_user_name: 'jdoe')
        expect(object_client).to have_received(:workflow).with('goobiWF')
        expect(workflow_client).to have_received(:create).with(version: 3)
      end
    end

    context 'when the version is already open' do
      let(:open) { true }

      before do
        allow(version_client).to receive(:open)
      end

      it 'starts goobiWF for the open version, keeping its description' do
        call

        expect(version_client).not_to have_received(:open)
        expect(object_client).to have_received(:workflow).with('goobiWF')
        expect(workflow_client).to have_received(:create).with(version: 2)
      end
    end

    context 'when the object is not an image or book Item' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.map) }

      it 'raises without starting goobiWF' do
        expect { call }.to raise_error(described_class::NotGoobiTypeError)
        expect(workflow_client).not_to have_received(:create)
      end
    end

    context 'when goobiWF was started for the open version' do
      let(:open) { true }
      let(:workflows_xml) do
        <<~XML
          <workflows objectId="#{druid}">
            <workflow objectId="#{druid}" id="goobiWF">
              <process version="2" status="completed" name="start"/>
              <process version="2" status="completed" name="goobi-notify"/>
            </workflow>
          </workflows>
        XML
      end

      it 'raises without starting goobiWF' do
        expect { call }.to raise_error(described_class::GoobiProcessingError)
        expect(workflow_client).not_to have_received(:create)
      end
    end

    context 'when a workflow is active' do
      let(:workflows_xml) do
        <<~XML
          <workflows objectId="#{druid}">
            <workflow objectId="#{druid}" id="accessionWF">
              <process version="1" status="queued" name="start-accession"/>
            </workflow>
          </workflows>
        XML
      end

      it 'raises without starting goobiWF' do
        expect { call }.to raise_error(described_class::ActiveWorkflowError)
        expect(workflow_client).not_to have_received(:create)
      end
    end

    context 'when starting goobiWF fails' do
      let(:open) { true }
      let(:response) { instance_double(Faraday::Response, status: 500, body: nil, reason_phrase: 'Server Error') }

      before do
        allow(workflow_client).to receive(:create).and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
      end

      it 'raises a repository error' do
        expect { call }.to raise_error(Sdr::Repository::Error, /Starting goobiWF failed/)
      end
    end
  end
end
