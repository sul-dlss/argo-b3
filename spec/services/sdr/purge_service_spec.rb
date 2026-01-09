# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::PurgeService do
  let(:druid) { 'druid:bc123cd4567' }

  describe '.can_purge?' do
    context 'when the object is not submitted' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
      end

      it 'returns true' do
        expect(described_class.can_purge?(druid:)).to be true
      end
    end

    context 'when the object is submitted' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(true)
      end

      it 'returns false' do
        expect(described_class.can_purge?(druid:)).to be false
      end
    end
  end

  describe '.purge' do
    let(:user_name) { 'testuser' }

    let(:object_client) { instance_double(Dor::Services::Client::Object, destroy: nil) }

    context 'when the object can be purged' do
      before do
        allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
      end

      it 'performs purge' do
        described_class.purge(druid:, user_name:)
        expect(object_client).to have_received(:destroy).with(user_name:)
      end
    end

    context 'when the object cannot be purged' do
      before do
        allow(Sdr::WorkflowService).to receive(:submitted?).with(druid:).and_return(true)
      end

      it 'raises CannotPurgeError' do
        expect { described_class.purge(druid:, user_name:) }.to raise_error(Sdr::PurgeService::CannotPurgeError)
      end
    end
  end
end
