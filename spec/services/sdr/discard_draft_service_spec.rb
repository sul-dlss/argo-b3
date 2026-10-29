# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::DiscardDraftService do
  subject(:discard_draft) { described_class.call(cocina_object:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, version:) }
  let(:version) { 2 }
  let(:open) { true }
  let(:discardable) { true }
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
      discard_draft

      expect(Sdr::VersionService).to have_received(:new).with(druid:)
      expect(version_service).to have_received(:discard)
      expect(Content.exists?(content.id)).to be false
      expect(Content.exists?(immutable_content.id)).to be true
      expect(StagingSupport.staged_files?(druid:)).to be false
    end
  end

  context 'when the open version is the first version' do
    let(:version) { 1 }

    it 'raises without discarding' do
      expect { discard_draft }.to raise_error(described_class::NotDiscardableError)

      expect(version_service).not_to have_received(:discard)
      expect(Content.exists?(content.id)).to be true
      expect(StagingSupport.staged_files?(druid:)).to be true
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

  describe '.discardable?' do
    subject(:discardable?) { described_class.discardable?(version: cocina_object.version, version_service:) }

    it { is_expected.to be true }

    context 'when the open version is the first version' do
      let(:version) { 1 }

      it { is_expected.to be false }
    end

    context 'when the version is closed' do
      let(:open) { false }

      it { is_expected.to be false }
    end

    context 'when SDR cannot discard the open version' do
      let(:discardable) { false }

      it { is_expected.to be false }
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
end
