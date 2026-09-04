# frozen_string_literal: true

module BulkActions
  # Controller for text extraction bulk action.
  class TextExtractionController < BulkActionApplicationController
    private

    def bulk_action_config
      BulkActions::TEXT_EXTRACTION
    end

    def job_params
      {
        druids: druids_from_form,
        text_extraction_languages: @bulk_action_form.text_extraction_languages
      }
    end
  end
end
