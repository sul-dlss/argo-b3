# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscardOrPurgePresenter do
  subject(:presenter) { described_class.new(cocina_version:, version_service:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:version_service) { instance_double(Sdr::VersionService, druid:) }

  before do
    allow(Sdr::PurgeService).to receive(:purgeable?).and_return(true)
    allow(Sdr::DiscardDraftService).to receive(:discardable?).and_return(false)
  end

  context 'with a first version' do
    let(:cocina_version) { 1 }

    it 'presents the purge button' do
      expect(presenter.purge?).to be true
      expect(presenter.label).to eq('Purge')
      expect(presenter.confirm).to start_with('Purge this object?')
      expect(presenter.path).to eq("/objects/#{druid}/purge")
    end

    it 'is available if the object is purgeable' do
      expect(presenter.available?).to be true
      expect(Sdr::PurgeService).to have_received(:purgeable?).with(druid:, version: 1)
      expect(Sdr::DiscardDraftService).not_to have_received(:discardable?)
    end
  end

  context 'with a later version' do
    let(:cocina_version) { 2 }

    it 'presents the discard draft button' do
      expect(presenter.purge?).to be false
      expect(presenter.label).to eq('Discard draft')
      expect(presenter.confirm).to start_with('Discard this draft?')
      expect(presenter.path).to eq("/objects/#{druid}/discard_draft")
    end

    it 'is available if the draft is discardable, checking only once' do
      2.times { expect(presenter.available?).to be false }
      expect(Sdr::DiscardDraftService).to have_received(:discardable?).with(version: 2, version_service:).once
      expect(Sdr::PurgeService).not_to have_received(:purgeable?)
    end
  end
end
