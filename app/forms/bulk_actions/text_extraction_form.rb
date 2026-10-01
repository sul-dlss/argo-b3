# frozen_string_literal: true

module BulkActions
  # Form for text extraction bulk action.
  class TextExtractionForm < BasicForm
    include TextExtractionConcern
  end
end
