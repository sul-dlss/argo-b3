# frozen_string_literal: true

# Concern for the OCR options / text extraction bulk action forms
module TextExtractionConcern
  extend ActiveSupport::Concern
  include NormalizationConcern

  included do
    # The OCR settings are not part of the Cocina object; they are saved with the content.
    attribute :run_ocr, :boolean, default: false

    attribute :text_extraction_languages, array: true, default: []
    # The multiple select submits a blank value alongside the selected languages.
    normalizes_array_compact_blank :text_extraction_languages
    validates :text_extraction_languages, presence: true, if: :run_ocr
  end

  # @param model [Content, MultiItemDepositAction] the model the OCR settings are saved with
  def prefill_ocr_settings(model)
    self.run_ocr = model.perform_ocr
    self.text_extraction_languages = model.ocr_languages
  end

  # @return [Hash] the OCR settings as attributes of the model they are saved with
  def ocr_settings_attributes
    { perform_ocr: run_ocr, ocr_languages: text_extraction_languages }
  end
end
