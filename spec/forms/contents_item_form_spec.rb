# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentsItemForm do
  subject(:contents_item_form) { described_class.build_from_cocina_object(cocina_object) }

  let(:cocina_object) do
    build(:dro_with_metadata, type: Cocina::Models::ObjectType.book)
      .then { |dro| dro.new(structural: dro.structural.new(hasMemberOrders: [{ viewingDirection: 'right-to-left' }])) }
  end

  describe '.permitted_params' do
    it 'permits the content type, viewing direction, and OCR settings' do
      expect(described_class.permitted_params).to eq([:content_type, :viewing_direction, :run_ocr,
                                                      { text_extraction_languages: [] }])
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
end
