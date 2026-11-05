# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::AdministrativeTags do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '.list' do
    let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: ['Project : Maps']) }

    it 'returns the tags' do
      expect(described_class.list(druid:)).to eq(['Project : Maps'])
    end

    context 'when the object is not found' do
      before do
        allow(tags_client).to receive(:list).and_raise(Dor::Services::Client::NotFoundResponse)
      end

      it 'raises' do
        expect { described_class.list(druid:) }.to raise_error(described_class::NotFoundResponse)
      end
    end
  end

  describe '.replace' do
    let(:tags_client) do
      instance_double(Dor::Services::Client::AdministrativeTags, replace: true, destroy: true,
                                                                 list: ['Old : One', 'Old : Two'])
    end

    it 'replaces the tags' do
      described_class.replace(druid:, tags: ['New : One'])

      expect(tags_client).to have_received(:replace).with(tags: ['New : One'])
      expect(tags_client).not_to have_received(:destroy)
    end

    context 'when the tags are empty' do
      it 'destroys each tag' do
        described_class.replace(druid:, tags: [])

        expect(tags_client).to have_received(:destroy).with(tag: 'Old : One')
        expect(tags_client).to have_received(:destroy).with(tag: 'Old : Two')
        expect(tags_client).not_to have_received(:replace)
      end
    end

    context 'when replacing fails' do
      let(:response) { instance_double(Faraday::Response, status: 409, body: nil, reason_phrase: 'Conflict') }

      before do
        allow(tags_client).to receive(:replace).and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
      end

      it 'raises' do
        expect { described_class.replace(druid:, tags: ['New : One']) }
          .to raise_error(described_class::Error, /Replacing administrative tags failed/)
      end
    end
  end
end
