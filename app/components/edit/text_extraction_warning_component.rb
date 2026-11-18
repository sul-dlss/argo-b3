# frozen_string_literal: true

module Edit
  # Component for the info alert warning against running text extraction (OCR or speech to text) needlessly.
  class TextExtractionWarningComponent < ApplicationComponent
    # @param ocr [Boolean] whether to warn about OCR
    # @param speech_to_text [Boolean] whether to warn about auto-generating captions and transcripts
    def initialize(ocr:, speech_to_text:)
      @ocr = ocr
      @speech_to_text = speech_to_text
      super()
    end

    attr_reader :ocr, :speech_to_text
  end
end
