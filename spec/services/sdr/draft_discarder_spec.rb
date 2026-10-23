# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::DraftDiscarder do
  subject(:discard_draft) { described_class.call(cocina_object:, user_name: 'jlittman') }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, version:) }
  let(:version) { 2 }
  let(:open) { true }
  let(:discardable) { true }
  let(:purgeable) { true }
  let(:version_service) { instance_double(Sdr::VersionService, discard: nil, open?: open, discardable?: discardable) }
  let(:staged_filepaths) do
    StagingSupport.locations.map do |staging_location|
      StagingSupport.staging_filepath(druid:, filepath: 'folder1/image1.tif', staging_location:)
    end
  end
  let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }
  let!(:immutable_content) { create(:content, druid:, lock: cocina_object.lock) }

  before do
    allow(Sdr::VersionService).to receive(:new).and_return(version_service)
    allow(Sdr::PurgeService).to receive(:can_purge?).and_return(purgeable)
    allow(Sdr::PurgeService).to receive(:purge)
    staged_filepaths.each do |staged_filepath|
      FileUtils.mkdir_p(File.dirname(staged_filepath))
      FileUtils.touch(staged_filepath)
    end
  end

  after do
    StagingSupport.delete_staged_files(druid:)
  end

  context 'when the open version is not the first version' do
    it 'discards the version and deletes the mutable content and staged files' do
      expect(discard_draft).to be false

      expect(Sdr::VersionService).to have_received(:new).with(druid:)
      expect(version_service).to have_received(:discard)
      expect(Sdr::PurgeService).not_to have_received(:purge)
      expect(Content.exists?(content.id)).to be false
      expect(Content.exists?(immutable_content.id)).to be true
      expect(StagingSupport.staged_files?(druid:)).to be false
    end
  end

  context 'when the open version is the first version' do
    let(:version) { 1 }
    let(:discardable) { false }

    it 'purges the object and deletes the mutable content and staged files' do
      expect(discard_draft).to be true

      expect(Sdr::PurgeService).to have_received(:can_purge?).with(druid:)
      expect(Sdr::PurgeService).to have_received(:purge).with(druid:, user_name: 'jlittman')
      expect(version_service).not_to have_received(:discard)
      expect(Content.exists?(content.id)).to be false
      expect(StagingSupport.staged_files?(druid:)).to be false
    end
  end

  context 'when the version is closed' do
    let(:open) { false }

    it 'raises without discarding' do
      expect { discard_draft }.to raise_error(described_class::NotDiscardableError)

      expect(version_service).not_to have_received(:discard)
      expect(Content.exists?(content.id)).to be true
    end
  end

  context 'when the open version is not discardable' do
    let(:discardable) { false }

    it 'raises without discarding' do
      expect { discard_draft }.to raise_error(described_class::NotDiscardableError)

      expect(version_service).not_to have_received(:discard)
    end
  end

  context 'when the open first version cannot be purged' do
    let(:version) { 1 }
    let(:purgeable) { false }

    it 'raises without purging' do
      expect { discard_draft }.to raise_error(described_class::NotDiscardableError)

      expect(Sdr::PurgeService).not_to have_received(:purge)
    end
  end

  context 'when the mutable content is staging' do
    let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging') }

    it 'raises without discarding' do
      expect { discard_draft }.to raise_error(described_class::ContentBusyError)

      expect(version_service).not_to have_received(:discard)
      expect(Content.exists?(content.id)).to be true
    end
  end

  context 'when discarding the version fails' do
    before do
      allow(version_service).to receive(:discard).and_raise(Sdr::VersionService::Error, 'Oops')
    end

    it 'raises without deleting the mutable content or staged files' do
      expect { discard_draft }.to raise_error(Sdr::VersionService::Error)

      expect(Content.exists?(content.id)).to be true
      expect(staged_filepaths).to all(satisfy { |staged_filepath| File.exist?(staged_filepath) })
    end
  end

  context 'when cleaning up fails' do
    before do
      allow(Content).to receive(:mutable_for).and_return(content)
      allow(content).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
      allow(Honeybadger).to receive(:notify)
    end

    it 'notifies without raising' do
      expect(discard_draft).to be false

      expect(Honeybadger).to have_received(:notify).with(ActiveRecord::RecordNotDestroyed, context: { druid: })
    end
  end
end
