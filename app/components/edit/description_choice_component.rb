# frozen_string_literal: true

module Edit
  # Component for rendering edit form for description choice
  # The form's object must include DescriptionChoiceFormConcern and, with item_fields, also CocinaModels::BarcodeConcern
  # and DescriptionCsvFormConcern. With abstract_field, it must also have an abstract attribute.
  class DescriptionChoiceComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder]
    # @param item_fields [Boolean] whether to render the fields that only apply to items: barcode and serials
    #   (part label and sort key) for FOLIO, and the description spreadsheet choice
    # @param abstract_field [Boolean] whether to render an abstract field with the title
    def initialize(form:, item_fields: true, abstract_field: false)
      @form = form
      @item_fields = item_fields
      @abstract_field = abstract_field
      super()
    end

    attr_reader :form

    # @return [Boolean]
    def abstract_field?
      @abstract_field
    end

    # @return [String]
    def title_choice_label
      return t('edit.collections.fields.description_choice.title.label') if abstract_field?

      t('edit.items.fields.description_choice.title.label')
    end

    # @return [Boolean]
    def item_fields?
      @item_fields
    end
  end
end
