# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::VersionService do
  subject(:service) { described_class.new(druid:) }

  let(:druid) { 'druid:bg139xz7624' }

  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, status:) }
  let(:status) { instance_double(Dor::Services::Client::ObjectVersion::VersionStatus) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '.close' do
    before do
      allow(version_client).to receive(:close)
    end

    it 'closes the version for the druid' do
      described_class.close(druid:, description: 'best version ever', user_name: 'mjgiarlo')
      expect(version_client).to have_received(:close).with(description: 'best version ever', user_name: 'mjgiarlo')
    end
  end

  describe '#open' do
    let(:options) do
      {
        description: 'best version ever',
        opening_user_name: 'mjgiarlo'
      }
    end

    before do
      allow(version_client).to receive(:open)
    end

    it 'delegates to the version client' do
      service.open(**options)
      expect(version_client).to have_received(:open).with(**options).once
    end

    context 'when the version client fails' do
      before do
        allow(version_client).to receive(:open).and_raise(Dor::Services::Client::Error, 'Oops')
      end

      it 'raises a version service error' do
        expect { service.open(**options) }.to raise_error(Sdr::VersionService::Error, 'Opening version failed: Oops')
      end
    end
  end

  describe '#close' do
    before do
      allow(version_client).to receive(:close)
    end

    it 'delegates to the version client' do
      service.close
      expect(version_client).to have_received(:close).once
    end

    context 'when the version client fails' do
      before do
        allow(version_client).to receive(:close).and_raise(Dor::Services::Client::Error, 'Oops')
      end

      it 'raises a version service error' do
        expect { service.close }.to raise_error(Sdr::VersionService::Error, 'Closing version failed: Oops')
      end
    end
  end

  describe '#update_description' do
    before do
      allow(version_client).to receive(:update_description)
    end

    it 'delegates to the version client' do
      service.update_description(description: 'Fixed the title', user_name: 'jlittman')
      expect(version_client).to have_received(:update_description)
        .with(description: 'Fixed the title', user_name: 'jlittman')
    end

    context 'when the version client fails' do
      before do
        allow(version_client).to receive(:update_description).and_raise(Dor::Services::Client::Error, 'Oops')
      end

      it 'raises a version service error' do
        expect { service.update_description(description: 'Fixed the title', user_name: 'jlittman') }
          .to raise_error(Sdr::VersionService::Error, 'Updating version description failed: Oops')
      end
    end
  end

  describe '#editable?' do
    before do
      allow(status).to receive_messages(openable?: openable, closeable?: closeable)
    end

    context 'when the version is closed and can be opened' do
      let(:openable) { true }
      let(:closeable) { false }

      it 'returns true' do
        expect(service.editable?).to be true
      end
    end

    context 'when the version is open and can be closed' do
      let(:openable) { false }
      let(:closeable) { true }

      it 'returns true' do
        expect(service.editable?).to be true
      end
    end

    # For example, when the version is being assembled or accessioned.
    context 'when the version can be neither opened nor closed' do
      let(:openable) { false }
      let(:closeable) { false }

      it 'returns false' do
        expect(service.editable?).to be false
      end
    end
  end

  describe '.editable?' do
    before do
      allow(status).to receive_messages(openable?: false, closeable?: true)
    end

    it 'returns whether the object for the druid can be edited' do
      expect(described_class.editable?(druid:)).to be true
    end
  end

  describe 'status methods' do
    it 'delegates to the version client' do
      %i[open? openable? assembling? accessioning? closed? closeable? version].each do |method|
        allow(status).to receive(method)
        service.send(method)
        expect(status).to have_received(method).once
      end
    end
  end
end
