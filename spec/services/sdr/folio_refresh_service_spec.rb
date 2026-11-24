# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::FolioRefreshService do
  subject(:service) do
    described_class.new(cocina_object:, user_name: 'jdoe', version_description: 'Refresh from FOLIO',
                        replace_open_version_description:)
  end

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a123']) }
  let(:refreshed_cocina_object) { cocina_object.new(lock: 'refreshed-lock') }
  let(:replace_open_version_description) { false }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, refresh_descriptive_metadata_from_ils: true)
  end
  let(:version_service) do
    version_service_double(open?: open, openable?: !open, version_description: 'Fixed the title', open: nil)
  end
  let(:open) { false }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Sdr::VersionService).to receive(:new).and_return(version_service)
    allow(Sdr::Repository).to receive(:find).and_return(refreshed_cocina_object)
  end

  context 'when the version is closed' do
    it 'opens a version, refreshes as the user, and returns the refreshed object' do
      expect(service.call).to eq refreshed_cocina_object

      expect(version_service).to have_received(:open)
        .with(description: 'Refresh from FOLIO', opening_user_name: 'jdoe')
      expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils).with(user_name: 'jdoe')
      expect(service.opened_version?).to be true
    end
  end

  context 'when the version is open' do
    let(:open) { true }

    it 'refreshes without opening a version or changing its description' do
      service.call

      expect(version_service).not_to have_received(:open)
      expect(version_service).not_to have_received(:update_description)
      expect(service.opened_version?).to be false
    end
  end

  context 'when the version is open and its description is replaced' do
    let(:open) { true }
    let(:replace_open_version_description) { true }

    it 'updates the description after refreshing' do
      service.call

      expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils).ordered
      expect(version_service).to have_received(:update_description)
        .with(description: 'Refresh from FOLIO', user_name: 'jdoe').ordered
    end
  end

  context 'when the open version already has the description' do
    let(:open) { true }
    let(:replace_open_version_description) { true }
    let(:version_service) { version_service_double(open?: true, version_description: 'Refresh from FOLIO') }

    it 'does not update the description' do
      service.call

      expect(version_service).not_to have_received(:update_description)
    end
  end

  context 'with a mutable content' do
    let(:open) { true }
    let!(:content) { Contents::Builder.call(cocina_object:, immutable: false) }

    it 'moves the content to the refreshed lock' do
      service.call

      expect(content.reload.lock).to eq 'refreshed-lock'
    end
  end

  context 'when updating the description fails after refreshing' do
    let(:open) { true }
    let(:replace_open_version_description) { true }
    let!(:content) { Contents::Builder.call(cocina_object:, immutable: false) }

    before do
      allow(version_service).to receive(:update_description)
        .and_raise(Sdr::VersionService::Error, 'Updating version description failed: oops')
    end

    it 'raises an error after moving the content to the refreshed lock' do
      expect { service.call }.to raise_error(described_class::Error, 'Updating version description failed: oops')

      expect(content.reload.lock).to eq 'refreshed-lock'
    end
  end

  context 'when the refresh fails' do
    let(:open) { true }
    let(:replace_open_version_description) { true }
    let(:response) { instance_double(Faraday::Response, status: 500, body: nil, reason_phrase: 'FOLIO is down') }

    before do
      allow(object_client).to receive(:refresh_descriptive_metadata_from_ils)
        .and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
    end

    it 'raises an error without changing the version description' do
      expect { service.call }.to raise_error(described_class::Error, /Refreshing from FOLIO failed: .*FOLIO is down/)

      expect(version_service).not_to have_received(:update_description)
    end
  end

  context 'when opening the version fails' do
    before do
      allow(version_service).to receive(:open).and_raise(Sdr::VersionService::Error, 'Opening version failed: oops')
    end

    it 'raises an error without refreshing' do
      expect { service.call }.to raise_error(described_class::Error, 'Opening version failed: oops')

      expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)
    end
  end
end
