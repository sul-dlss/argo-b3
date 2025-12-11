# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkAction do
  describe '.bulk_action_config' do
    subject(:bulk_action) { described_class.new(action_type: :reindex) }

    it 'returns the correct config for the action type' do
      expect(bulk_action.bulk_action_config).to eq(BulkActions::REINDEX)
    end
  end

  describe '.enqueue_job' do
    subject(:bulk_action) { described_class.create!(action_type: :reindex, user:) }

    let(:user) { create(:user) }
    let(:druids) { ['druid:ab123cd4567', 'druid:ef789gh0123'] }

    it 'enqueues the correct job and updates status to queued' do
      expect do
        bulk_action.enqueue_job(druids:)
      end.to have_enqueued_job(BulkActions::ReindexJob).with(bulk_action:, druids:)

      expect(bulk_action.status).to eq('queued')
    end
  end
end
