# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Content do
  let(:druid) { 'druid:bc123df4567' }

  describe 'staging state' do
    it 'can start staging again after failing staging' do
      content = create(:content, staging_state: 'staging_failed')

      content.staging_started!

      expect(content.reload.staging_state).to eq('staging')
    end

    it 'fails staging from staging' do
      content = create(:content, staging_state: 'staging')

      content.staging_errored!

      expect(content.reload.staging_state).to eq('staging_failed')
    end

    it 'clears a staging failure' do
      content = create(:content, staging_state: 'staging_failed')

      content.staging_failure_cleared!

      expect(content.reload.staging_state).to eq('staging_not_in_progress')
    end
  end

  describe '.latest_staging_activity' do
    before do
      create(:content, druid:, lock: 'lock-1', staging_state: 'staging_not_in_progress', updated_at: 1.minute.ago)
      create(:content, druid: 'druid:df123bc4589', lock: 'lock-1', staging_state: 'staging')
    end

    context 'when no content for the druid is staging or failed staging' do
      it 'returns nil' do
        expect(described_class.latest_staging_activity(druid:)).to be_nil
      end
    end

    context 'when content for the druid is staging, regardless of lock or immutability' do
      let!(:staging_content) do
        create(:content, druid:, lock: 'lock-2', immutable: true, staging_state: 'staging', updated_at: 2.minutes.ago)
      end

      it 'returns the staging content' do
        expect(described_class.latest_staging_activity(druid:)).to eq(staging_content)
      end
    end

    context 'when multiple contents for the druid are staging or failed staging' do
      let!(:latest_content) do
        create(:content, druid:, lock: 'lock-3', immutable: false, staging_state: 'staging_failed',
                         updated_at: 1.minute.ago)
      end

      before do
        create(:content, druid:, lock: 'lock-2', staging_state: 'staging', updated_at: 2.minutes.ago)
      end

      it 'returns the most recently updated' do
        expect(described_class.latest_staging_activity(druid:)).to eq(latest_content)
      end
    end
  end
end
