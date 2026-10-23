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
  end
end
