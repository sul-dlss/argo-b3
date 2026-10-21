# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Content do
  let(:druid) { 'druid:bc123df4567' }

  describe '.mutable_for' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid).new(lock: 'current-lock') }
    let!(:mutable_content) { create(:content, :mutable, druid:, lock: 'current-lock') }

    before do
      create(:content, druid:, lock: 'current-lock', immutable: true)
      create(:content, :mutable, druid:, lock: 'old-lock')
      create(:content, :mutable, druid: 'druid:dj123df4598', lock: 'current-lock')
    end

    it 'returns the mutable Content for the lock of the object' do
      expect(described_class.mutable_for(cocina_object)).to eq(mutable_content)
    end
  end

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
        create(:content, :mutable, druid:, lock: 'lock-3', staging_state: 'staging_failed',
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

  describe '#workflow_context' do
    context 'when performing OCR' do
      subject(:content) { build(:content, perform_ocr: true, ocr_languages: %w[English Spanish]) }

      it 'requests OCR in the languages' do
        expect(content.workflow_context).to eq({ runOCR: true, ocrLanguages: %w[English Spanish] })
      end
    end

    context 'when not performing OCR' do
      subject(:content) { build(:content, perform_ocr: false) }

      it 'is empty' do
        expect(content.workflow_context).to eq({})
      end
    end
  end

  describe '#staging_or_discovering?' do
    it 'is true only while staging or discovering' do
      expect(build(:content, staging_state: 'staging')).to be_staging_or_discovering
      expect(build(:content, mount_state: 'discovering')).to be_staging_or_discovering
      expect(build(:content, staging_state: 'staging_failed')).not_to be_staging_or_discovering
    end
  end

  describe '#clear_other_staging_failures!' do
    subject(:content) { create(:content, druid:, lock: 'lock-2', staging_state: 'staging_failed') }

    let!(:other_failed_content) { create(:content, druid:, lock: 'lock-1', staging_state: 'staging_failed') }
    let!(:other_object_failed_content) do
      create(:content, druid: 'druid:df123bc4589', lock: 'lock-1', staging_state: 'staging_failed')
    end

    it 'clears staging failures for other contents for the druid only' do
      content.clear_other_staging_failures!

      expect(content.reload.staging_state).to eq('staging_failed')
      expect(other_failed_content.reload.staging_state).to eq('staging_not_in_progress')
      expect(other_object_failed_content.reload.staging_state).to eq('staging_failed')
    end
  end
end
