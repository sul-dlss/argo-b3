# frozen_string_literal: true

module BulkActions
  # Form for text extraction bulk action.
  class TextExtractionForm < BasicForm
    attribute :text_extraction_languages, array: true, default: []
  end
end
