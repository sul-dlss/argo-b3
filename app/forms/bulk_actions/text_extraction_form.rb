# frozen_string_literal: true

module BulkActions
  # Form for text extraction bulk action.
  class TextExtractionForm < BasicForm
    include TextExtractionConcern

    def job_params
      { ocr_languages: }
    end
  end
end
