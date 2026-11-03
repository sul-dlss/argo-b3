# frozen_string_literal: true

# Concern for the text extraction (OCR and speech to text) options / text extraction bulk action forms
module TextExtractionConcern
  extend ActiveSupport::Concern
  include NormalizationConcern

  included do
    # The text extraction settings are not part of the Cocina object; they are saved with the content.
    attribute :perform_ocr, :boolean, default: false

    attribute :ocr_languages, array: true, default: []
    # The multiple select submits a blank value alongside the selected languages.
    normalizes_array_compact_blank :ocr_languages
    validates :ocr_languages, presence: true, if: :perform_ocr

    attribute :perform_speech_to_text, :boolean, default: false
  end

  # @param model [Content, MultiItemDepositAction] the model the text extraction settings are saved with
  def prefill_text_extraction_settings(model)
    self.perform_ocr = model.perform_ocr
    self.ocr_languages = model.ocr_languages
    self.perform_speech_to_text = model.perform_speech_to_text
  end

  # @return [Hash] the text extraction settings as attributes of the model they are saved with
  def text_extraction_settings_attributes
    { perform_ocr:, ocr_languages:, perform_speech_to_text: }
  end
end
