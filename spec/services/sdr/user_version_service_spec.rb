# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::UserVersionService do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, user_version: user_version_client) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: [user_version]) }
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
end
