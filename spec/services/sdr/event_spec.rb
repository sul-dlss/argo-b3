# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::Event do
  let(:druid) { 'druid:bc123df4567' }
  let(:type) { 'argo_permission_created' }
  let(:data) { { who: 'jdoe', host: 'argo-test.stanford.edu', permission_type: 'edit' } }

  describe '#create' do
    context 'when rabbitmq is enabled' do
      before do
        allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
        allow(Dor::Event::Client).to receive(:create)
      end

      it 'publishes the event' do
        described_class.create(druid:, type:, data:)

        expect(Dor::Event::Client).to have_received(:create).with(druid:, type:, data:)
      end
    end

    context 'when rabbitmq is not enabled' do
      before do
        allow(Settings.rabbitmq).to receive(:enabled).and_return(false)
        allow(Dor::Event::Client).to receive(:create)
      end

      it 'does not publish the event' do
        described_class.create(druid:, type:, data:)

        expect(Dor::Event::Client).not_to have_received(:create)
      end
    end

    context 'when publishing the event fails' do
      before do
        allow(Settings.rabbitmq).to receive(:enabled).and_return(true)
        allow(Dor::Event::Client).to receive(:create).and_raise(Dor::Event::Client::Error, 'Broken')
      end

      it 'raises' do
        expect { described_class.create(druid:, type:, data:) }.to raise_error(Sdr::Event::Error)
      end
    end
  end

  describe '.list' do
    let(:events) { [Dor::Services::Client::Events::Event.new(event_type: 'version_open', data: {}, timestamp: '2026-10-01T12:00:00Z')] }
    let(:events_client) { instance_double(Dor::Services::Client::Events, list: events) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, events: events_client) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when the object is found' do
      it 'returns the events' do
        expect(described_class.list(druid:, event_types: ['version_open'], from: '2026-10-01', to: '2026-10-02'))
          .to eq(events)

        expect(Dor::Services::Client).to have_received(:object).with(druid)
        expect(events_client).to have_received(:list)
          .with(event_types: ['version_open'], from: '2026-10-01', to: '2026-10-02')
      end
    end

    context 'when no filters are provided' do
      it 'lists all events' do
        described_class.list(druid:)

        expect(events_client).to have_received(:list).with(event_types: nil, from: nil, to: nil)
      end
    end

    context 'when the object is not found' do
      let(:events) { nil }

      it 'raises' do
        expect { described_class.list(druid:) }.to raise_error(Sdr::Event::NotFoundResponse)
      end
    end

    context 'when retrieving the events fails' do
      before do
        allow(events_client).to receive(:list).and_raise(Dor::Services::Client::Error, 'Invalid from')
      end

      it 'raises' do
        expect { described_class.list(druid:, from: 'bad') }.to raise_error(Sdr::Event::Error)
      end
    end
  end

  describe '.types' do
    let(:event_types_client) { instance_double(Dor::Services::Client::EventTypes) }

    before do
      allow(Dor::Services::Client).to receive(:event_types).and_return(event_types_client)
    end

    context 'when the event types are retrieved' do
      before do
        allow(event_types_client).to receive(:list).and_return(%w[publishing_complete version_open])
      end

      it 'returns the event types' do
        expect(described_class.types).to eq(%w[publishing_complete version_open])
      end
    end

    context 'when retrieving the event types fails' do
      before do
        allow(event_types_client).to receive(:list).and_raise(Dor::Services::Client::Error, 'Broken')
      end

      it 'raises' do
        expect { described_class.types }.to raise_error(Sdr::Event::Error)
      end
    end
  end
end
