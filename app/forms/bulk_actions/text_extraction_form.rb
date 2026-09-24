# frozen_string_literal: true

module BulkActions
  # Form for text extraction bulk action.
  class TextExtractionForm < BasicForm
    include NormalizationConcern

    attribute :text_extraction_languages, array: true, default: []
    # The multiple select submits a blank value alongside the selected languages.
    normalizes_array_compact_blank :text_extraction_languages
  end
end
