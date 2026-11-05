# frozen_string_literal: true

module Edit
  # Component for rendering edit form for speech to text settings
  # The form's object must include TextExtractionConcern.
  class SpeechToTextComponent < ApplicationComponent
    # @param data [Hash] data attributes for the fieldset (e.g., to make it a content-type-dependent target)
    def initialize(form:, data: {})
      @form = form
      @data = data
      super()
    end

    attr_reader :form, :data
  end
end
