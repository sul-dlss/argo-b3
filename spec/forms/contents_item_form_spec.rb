# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentsItemForm do
  subject(:contents_item_form) { described_class.build_from_cocina_object(cocina_object) }

  let(:cocina_object) do
    build(:dro_with_metadata, type: Cocina::Models::ObjectType.book)
      .then { |dro| dro.new(structural: dro.structural.new(hasMemberOrders: [{ viewingDirection: 'right-to-left' }])) }
  end
  # Defaults to the initial version, for which a version description is not required.
  let(:version_service) do
    version_service_double(open?: true, version: 1, version_description: 'Initial version')
  end

  before do
    allow(Sdr::VersionService).to receive(:new).and_return(version_service)
  end

  describe '.permitted_params' do
    it 'permits the content type, viewing direction, OCR settings, and version description' do
      expect(described_class.permitted_params).to eq([:content_type, :viewing_direction, :run_ocr,
                                                      :version_description, { text_extraction_languages: [] }])
    end
  end

  context 'when changing to a content type that has viewing directions' do
    before do
      contents_item_form.update(content_type: Cocina::Models::ObjectType.image)
    end

    it 'retains the viewing direction' do
      expect(contents_item_form).to be_valid
      expect(contents_item_form.viewing_direction).to eq('right-to-left')
    end
  end

  context 'when changing to a content type that does not have viewing directions' do
    before do
      contents_item_form.update(content_type: Cocina::Models::ObjectType.map)
    end

    it 'clears the viewing direction' do
      expect(contents_item_form).to be_valid
      expect(contents_item_form.viewing_direction).to be_nil
    end
  end

  context 'when running OCR' do
    before do
      contents_item_form.update(run_ocr: true, text_extraction_languages: ['', 'English'])
    end

    it 'retains the languages, less the blank value submitted by the select' do
      expect(contents_item_form).to be_valid
      expect(contents_item_form.run_ocr).to be true
      expect(contents_item_form.text_extraction_languages).to eq(['English'])
    end

    it 'requests OCR in the workflow context' do
      expect(contents_item_form.workflow_context).to eq({ runOcr: true, ocrLanguages: ['English'] })
    end

    it 'does not change the form' do
      expect(contents_item_form).not_to be_changed
    end
  end

  context 'when not running OCR' do
    before do
      contents_item_form.update(run_ocr: false, text_extraction_languages: ['English'])
    end

    it 'clears the languages' do
      expect(contents_item_form).to be_valid
      expect(contents_item_form.text_extraction_languages).to eq([])
    end

    it 'has an empty workflow context' do
      expect(contents_item_form.workflow_context).to eq({})
    end
  end

  context 'when running OCR without a language' do
    before do
      contents_item_form.update(run_ocr: true, text_extraction_languages: [])
    end

    it 'is not valid' do
      expect(contents_item_form).not_to be_valid
      expect(contents_item_form.errors[:text_extraction_languages]).to be_present
    end
  end

  context 'when changing to a content type that cannot be OCRed' do
    before do
      contents_item_form.update(content_type: Cocina::Models::ObjectType.map, run_ocr: true,
                                text_extraction_languages: ['English'])
    end

    it 'clears the OCR settings' do
      expect(contents_item_form).to be_valid
      expect(contents_item_form.run_ocr).to be false
      expect(contents_item_form.text_extraction_languages).to eq([])
    end
  end

  context 'with an invalid viewing direction' do
    before do
      contents_item_form.update(viewing_direction: 'upside-down')
    end

    it 'is not valid' do
      expect(contents_item_form).not_to be_valid
      expect(contents_item_form.errors[:viewing_direction]).to be_present
    end
  end

  context 'with content that is invalid for the content type' do
    # A dark object's content errors are only warnings.
    let(:cocina_object) do
      build(:dro_with_metadata, type: Cocina::Models::ObjectType.book).new(access: { view: 'world', download: 'world' })
    end
    let(:content) { create(:content, druid: cocina_object.externalIdentifier, lock: cocina_object.lock) }

    before do
      # Published files in a file resource are an error for a book.
      create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'file'),
                            publish: true)
      contents_item_form.content = content
    end

    it 'is not valid when depositing' do
      expect(contents_item_form.valid?(:deposit)).to be false
      expect(contents_item_form.errors[:content]).to eq(['Content errors must be fixed.'])
    end

    it 'is valid when not depositing' do
      expect(contents_item_form).to be_valid
    end

    it 'is valid when depositing as a content type for which the content is valid' do
      contents_item_form.update(content_type: Cocina::Models::ObjectType.object)

      expect(contents_item_form.valid?(:deposit)).to be true
    end

    it 'is not changed by setting the content' do
      expect(contents_item_form).not_to be_changed
    end
  end

  describe 'version description' do
    context 'when the initial version' do
      it 'is not required' do
        expect(contents_item_form).to be_initial_version
        expect(contents_item_form).to be_valid
      end
    end

    context 'when not the initial version' do
      let(:version_service) do
        version_service_double(open?: false, version: 1, version_description: 'Initial version')
      end

      it 'is required' do
        expect(contents_item_form).not_to be_initial_version
        expect(contents_item_form).not_to be_valid
        expect(contents_item_form.errors[:version_description]).to include("can't be blank")
      end
    end

    it 'does not change the form' do
      contents_item_form.update(version_description: 'Added files')

      expect(contents_item_form).not_to be_changed
    end
  end

  describe '#prefill_version_description' do
    context 'when the version is open' do
      it 'prefills the description of the open version' do
        contents_item_form.prefill_version_description

        expect(contents_item_form.version_description).to eq('Initial version')
      end
    end

    context 'when the version is closed' do
      let(:version_service) do
        version_service_double(open?: false, version: 1, version_description: 'Initial version')
      end

      it 'leaves the description blank' do
        contents_item_form.prefill_version_description

        expect(contents_item_form.version_description).to be_nil
      end
    end
  end

  describe '#save!' do
    let(:user_name) { 'jlittman' }
    let(:version_service) do
      version_service_double(open?: open, version:, version_description: 'Added files')
    end
    let(:version) { 2 }
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }

    before do
      allow(Sdr::VersionService).to receive(:open).and_return(opened_cocina_object)
      allow(Sdr::Repository).to receive(:update)
    end

    context 'when the version is closed and there are no changes' do
      let(:open) { false }
      let(:content) { create(:content, druid: cocina_object.externalIdentifier, lock: cocina_object.lock) }

      before do
        contents_item_form.update(version_description: 'Added more files')
        contents_item_form.content = content
      end

      it 'opens a new version without saving and rebases the content onto it' do
        contents_item_form.save!(user_name:)

        expect(Sdr::VersionService).to have_received(:open)
          .with(druid: cocina_object.externalIdentifier, description: 'Added more files', opening_user_name: user_name)
        expect(contents_item_form.previous_cocina_object).to eq(opened_cocina_object)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload.lock).to eq('opened-lock')
      end
    end

    context 'when saving fails after opening a version' do
      let(:open) { false }
      let(:content) { create(:content, druid: cocina_object.externalIdentifier, lock: cocina_object.lock) }

      before do
        allow(Sdr::Repository).to receive(:update).and_raise(Sdr::Repository::Error, 'Update failed')
        contents_item_form.update(version_description: 'Changed type', content_type: Cocina::Models::ObjectType.image)
        contents_item_form.content = content
      end

      it 'rebases the content onto the opened version' do
        expect { contents_item_form.save!(user_name:) }.to raise_error(Sdr::Repository::Error)
        expect(content.reload.lock).to eq('opened-lock')
      end
    end

    context 'when the version is open and the version description changed' do
      let(:open) { true }

      before { contents_item_form.update(version_description: 'Added more files') }

      it 'updates the version description without opening a version' do
        contents_item_form.save!(user_name:)

        expect(version_service).to have_received(:update_description)
          .with(description: 'Added more files', user_name:)
        expect(Sdr::VersionService).not_to have_received(:open)
      end
    end

    context 'when the version is open and the version description did not change' do
      let(:open) { true }

      before { contents_item_form.update(version_description: 'Added files') }

      it 'does not update the version description' do
        contents_item_form.save!(user_name:)

        expect(version_service).not_to have_received(:update_description)
        expect(Sdr::VersionService).not_to have_received(:open)
      end
    end

    context 'when the initial version' do
      let(:open) { true }
      let(:version) { 1 }

      it 'does not update the version description' do
        contents_item_form.save!(user_name:)

        expect(version_service).not_to have_received(:update_description)
        expect(Sdr::VersionService).not_to have_received(:open)
      end
    end

    context 'when only the OCR settings changed' do
      let(:open) { true }
      let(:version) { 1 }

      before { contents_item_form.update(run_ocr: true, text_extraction_languages: ['English']) }

      it 'does not update the cocina object' do
        contents_item_form.save!(user_name:)

        expect(Sdr::Repository).not_to have_received(:update)
        expect(contents_item_form.workflow_context).to eq({ runOcr: true, ocrLanguages: ['English'] })
      end
    end

    context 'when the version description is missing' do
      let(:open) { false }
      let(:content) { create(:content, druid: cocina_object.externalIdentifier, lock: cocina_object.lock) }

      before { contents_item_form.content = content }

      it 'raises without opening a version or changing the content lock' do
        expect { contents_item_form.save!(user_name:) }.to raise_error(ActiveModel::ValidationError)
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(content.reload.lock).to eq(cocina_object.lock)
      end
    end
  end
end
