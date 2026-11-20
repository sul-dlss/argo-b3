# frozen_string_literal: true

module Edit
  # Component for selecting the use (role) of a file.
  # The user can select a common use or enter another one.
  # The form's object must provide use.
  class UseComponent < ApplicationComponent
    # Ordered from most to least common in SDR.
    USES = %w[
      transcription
      master
      derivative
      thumbnail
      caption
      annotations
      georeference
    ].freeze

    # @param form [ActionView::Helpers::FormBuilder] a nested form builder for a ContentFileForm
    # @param label_text [String] the visually hidden label, which names the file (the field is in a table row)
    def initialize(form:, label_text:)
      @form = form
      @label_text = label_text
      super()
    end

    attr_reader :form, :label_text

    # Includes the current use when it is not a common one, so that it remains selected.
    def options
      use = form.object.use
      return USES if use.blank? || USES.include?(use)

      [use, *USES]
    end
  end
end
