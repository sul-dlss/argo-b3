# frozen_string_literal: true

module Edit
  # Component for rendering edit form for OCR text extraction settings
  class OcrComponent < ApplicationComponent
    # Content types whose files commonly already contain text, so OCR would be redundant.
    EMBEDDED_TEXT_CONTENT_TYPES = [Cocina::Models::ObjectType.document].freeze

    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
