# frozen_string_literal: true

# Concern for the OCR options / text extraction bulk action forms
module TextExtractionConcern
  extend ActiveSupport::Concern
  include NormalizationConcern

  included do
    attribute :text_extraction_languages, array: true, default: []
    # The multiple select submits a blank value alongside the selected languages.
    normalizes_array_compact_blank :text_extraction_languages
  end
end
