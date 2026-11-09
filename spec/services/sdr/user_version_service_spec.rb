# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::UserVersionService do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, user_version: user_version_client) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: [user_version], update: nil) }
  let(:user_version) { Dor::Services::Client::UserVersion::Version.new(version: 1, userVersion: 1) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe '.inventory' do
    it 'returns the user versions' do
      expect(described_class.inventory(druid:)).to eq([user_version])
      expect(Dor::Services::Client).to have_received(:object).with(druid)
    end

    context 'when the user version client fails' do
      before do
        allow(user_version_client).to receive(:inventory).and_raise(Dor::Services::Client::Error, 'Oops')
      end

      it 'raises a user version service error' do
        expect { described_class.inventory(druid:) }
          .to raise_error(Sdr::UserVersionService::Error, 'Retrieving user versions failed: Oops')
      end
    end
  end

  describe '.update' do
    it 'withdraws the user version' do
      described_class.update(druid:, user_version: 2, withdraw: true)

      expect(Dor::Services::Client).to have_received(:object).with(druid)
      expect(user_version_client).to have_received(:update)
        .with(user_version: Dor::Services::Client::UserVersion::Version.new(userVersion: 2, withdrawn: true))
    end

    it 'restores the user version' do
      described_class.update(druid:, user_version: 2, withdraw: false)

      expect(user_version_client).to have_received(:update)
        .with(user_version: Dor::Services::Client::UserVersion::Version.new(userVersion: 2, withdrawn: false))
    end

    context 'when the user version client fails' do
      before do
        allow(user_version_client).to receive(:update).and_raise(Dor::Services::Client::Error, 'Oops')
      end

      it 'raises a user version service error' do
        expect { described_class.update(druid:, user_version: 2, withdraw: true) }
          .to raise_error(Sdr::UserVersionService::Error, 'Updating user version failed: Oops')
      end
    end
  end
end
