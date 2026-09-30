# frozen_string_literal: true

module Edit
  # Component for rendering edit form for description choice
  class DescriptionChoiceComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    # FieldComponent performs this wiring for the fields it renders, but the Folio Instance HRID input is
    # rendered on its own so that the "Retrieve title" button can sit beside it in an input group.
    def catalog_record_id_aria
      SdrViewComponents::Forms::InvalidFeedbackSupport.arias_for(field_name: :catalog_record_id, form:)
    end

    # The retrieved title field is disabled until a title has been retrieved, whether by the
    # catalog-title Stimulus controller or by a previous submission of the form.
    def retrieved_title_disabled?
      form.object.retrieved_title.blank?
    end
  end
end
