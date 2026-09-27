# frozen_string_literal: true

module Edit
  # Component for selecting the use (role) of a file.
  # The user can select a common use or enter another one.
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
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    # Includes the current use when it is not a common one, so that it remains selected.
    def options
      use = form.object.use
      return USES if use.blank? || USES.include?(use)

      [use, *USES]
    end
  end
end
