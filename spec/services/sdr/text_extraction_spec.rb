# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::TextExtraction do
  subject(:text_extraction) { described_class.new(cocina_object, languages:, already_opened:) }

  let(:druid) { 'druid:bg139xz7624' }
  let(:version) { 2 }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: dro, externalIdentifier: druid, version:, type: object_type) }
  let(:languages) { ['English'] }
  let(:dro) { true }
  let(:object_type) { Cocina::Models::ObjectType.document }
  let(:already_opened) { true }

  before do
    allow(Settings.feature_flags).to receive(:ocr_workflow).and_return(true)
  end

  describe '#ocr_able?' do
    context 'when the object is a document' do
      let(:object_type) { Cocina::Models::ObjectType.document }

      it 'returns true' do
        expect(text_extraction.ocr_able?).to be true
      end
    end

    context 'when the object is an image' do
      let(:object_type) { Cocina::Models::ObjectType.image }

      it 'returns true' do
        expect(text_extraction.ocr_able?).to be true
      end
    end

    context 'when the object is a book' do
      let(:object_type) { Cocina::Models::ObjectType.book }

      it 'returns true' do
        expect(text_extraction.ocr_able?).to be true
      end

      context 'when ocr_workflow is disabled' do
        before do
          allow(Settings.feature_flags).to receive(:ocr_workflow).and_return(false)
        end

        it 'returns false' do
          expect(text_extraction.ocr_able?).to be false
        end
      end
    end

    context 'when the object is media' do
      let(:object_type) { Cocina::Models::ObjectType.media }

      it 'returns false' do
        expect(text_extraction.ocr_able?).to be false
      end
    end

    context 'when the object is not an item' do
      let(:dro) { false }

      it 'returns false' do
        expect(text_extraction.ocr_able?).to be false
      end
    end

    context 'when the object is not a document, image or book' do
      let(:object_type) { Cocina::Models::ObjectType.map }

      it 'returns false' do
        expect(text_extraction.ocr_able?).to be false
      end
    end
  end

  describe '#call' do
    let(:fake_object_client) { instance_double(Dor::Services::Client::Object, workflow: fake_workflow_client) }
    let(:fake_workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true) }
    let(:ocr_context) { { manuallyCorrectedOCR: false, ocrLanguages: languages } }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(fake_object_client)
    end

    context 'when the object is already opened' do
      context 'when the object is a document' do
        let(:object_type) { Cocina::Models::ObjectType.document }

        it 'starts ocrWF and returns true' do
          expect(text_extraction.call).to be true
          expect(fake_workflow_client).to have_received(:create).with(version:, lane_id: 'low', context: ocr_context)
        end
      end

      context 'when the object is media' do
        let(:object_type) { Cocina::Models::ObjectType.media }

        it 'does not start ocrWF' do
          text_extraction.call

          expect(fake_workflow_client).not_to have_received(:create)
        end
      end
    end

    context 'when the object is not already opened' do
      let(:already_opened) { false }
      let(:object_type) { Cocina::Models::ObjectType.document }

      it 'starts ocrWF for the next version and returns true' do
        expect(text_extraction.call).to be true
        expect(fake_workflow_client).to have_received(:create).with(version: version + 1, lane_id: 'low',
                                                                    context: ocr_context)
      end
    end

    context 'when the object is not an item' do
      let(:dro) { false }

      it 'does not start ocrWF' do
        text_extraction.call

        expect(fake_workflow_client).not_to have_received(:create)
      end
    end

    context 'when the object is not a document, image or book' do
      let(:object_type) { Cocina::Models::ObjectType.map }

      it 'does not start ocrWF' do
        text_extraction.call

        expect(fake_workflow_client).not_to have_received(:create)
      end
    end
  end
end
