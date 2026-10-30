# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::DepositDraftService do
  subject(:deposit_draft) { described_class.call(cocina_object:, user_name: 'jdoe') }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:version_service) { version_service_double(open?: open, closeable?: closeable) }
  let(:open) { true }
  let(:closeable) { true }

  before do
    allow(Sdr::VersionService).to receive(:new).and_return(version_service)
    allow(Sdr::Repository).to receive(:accession)
  end

  context 'with a mutable content without unsaved changes' do
    let!(:content) do
      Contents::Builder.call(cocina_object:, immutable: false).tap do |content|
        content.update!(perform_ocr: true, ocr_languages: ['English'])
      end
    end

    it 'accessions with the OCR settings and deletes the mutable content' do
      deposit_draft

      expect(Sdr::VersionService).to have_received(:new).with(druid:)
      expect(Sdr::Repository).to have_received(:accession)
        .with(cocina_object:, user_name: 'jdoe', context: { runOCR: true, ocrLanguages: ['English'] })
      expect(Content.exists?(content.id)).to be false
    end
  end

  context 'without a mutable content' do
    it 'accessions without a context' do
      deposit_draft

      expect(Sdr::Repository).to have_received(:accession).with(cocina_object:, user_name: 'jdoe', context: {})
    end
  end

  context 'when the mutable content is staging' do
    before { create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging') }

    it 'raises without accessioning' do
      expect { deposit_draft }.to raise_error(described_class::ContentBusyError)

      expect(Sdr::Repository).not_to have_received(:accession)
    end
  end

  context 'when the version is not open' do
    let(:open) { false }

    it 'raises without accessioning' do
      expect { deposit_draft }.to raise_error(described_class::NotDepositableError)

      expect(Sdr::Repository).not_to have_received(:accession)
    end
  end

  context 'when the version cannot be closed' do
    let(:closeable) { false }

    it 'raises without accessioning' do
      expect { deposit_draft }.to raise_error(described_class::NotDepositableError)

      expect(Sdr::Repository).not_to have_received(:accession)
    end
  end

  context 'when the mutable content has unsaved changes' do
    let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }

    before { create(:content_file_binary, content:, file_location: 'attached') }

    it 'raises without accessioning or deleting the mutable content' do
      expect { deposit_draft }.to raise_error(described_class::UnsavedChangesError)

      expect(Sdr::Repository).not_to have_received(:accession)
      expect(Content.exists?(content.id)).to be true
    end
  end

  context 'when the content is invalid for the content type' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(access: { view: 'world', download: 'world' })
    end

    before do
      content = create(:content, druid:, lock: cocina_object.lock)
      # Published files in a file resource are an error for a book.
      create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'file'),
                            publish: true)
    end

    it 'raises without accessioning' do
      expect { deposit_draft }.to raise_error(described_class::InvalidContentError)

      expect(Sdr::Repository).not_to have_received(:accession)
    end
  end

  context 'with a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'accessions without checking content' do
      deposit_draft

      expect(Sdr::Repository).to have_received(:accession).with(cocina_object:, user_name: 'jdoe', context: {})
      expect(Content.exists?(druid:)).to be false
    end
  end
end
