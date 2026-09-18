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
end
