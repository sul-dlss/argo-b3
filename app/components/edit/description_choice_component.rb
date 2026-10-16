# frozen_string_literal: true

module Edit
  # Component for rendering edit form for description choice
  class DescriptionChoiceComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    # FieldComponent performs this wiring for the fields it renders, but the FOLIO fields are rendered on
    # their own so that each label can sit to the left of its input (and the "Preview FOLIO record" button
    # beside the Folio Instance HRID input).
    def field_aria(field_name)
      SdrViewComponents::Forms::InvalidFeedbackSupport.arias_for(field_name:, form:)
    end

    # The retrieved title is hidden until a title has been retrieved, whether by the
    # catalog-title Stimulus controller or by a previous submission of the form.
    def retrieved_title_hidden?
      form.object.retrieved_title.blank?
    end
  end
end
