# frozen_string_literal: true

module Edit
  # Component for rendering edit form for description choice
  # The form's object must include DescriptionChoiceFormConcern.
  class DescriptionChoiceComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder]
    # @param item_fields [Boolean] whether to render the fields that only apply to items: barcode and serials
    #   (part label and sort key) for FOLIO, and the description spreadsheet choice
    def initialize(form:, item_fields: true)
      @form = form
      @item_fields = item_fields
      super()
    end

    attr_reader :form

    # @return [Boolean]
    def item_fields?
      @item_fields
    end

    # FieldComponent performs this wiring for the fields it renders, but the Folio Instance HRID input is
    # rendered on its own so that the "Preview FOLIO record" button can sit beside it.
    # @return [Hash] the aria attributes for the Folio Instance HRID input
    def catalog_record_id_aria
      SdrViewComponents::Forms::InvalidFeedbackSupport.arias_for(field_name: :catalog_record_id, form:)
    end

    # The retrieved title is hidden until a title has been retrieved, whether by the
    # catalog-title Stimulus controller or by a previous submission of the form.
    # @return [Boolean]
    def retrieved_title_hidden?
      form.object.retrieved_title.blank?
    end
  end
end
