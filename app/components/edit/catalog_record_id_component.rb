# frozen_string_literal: true

module Edit
  # Component for rendering the Folio Instance HRID field with a button to retrieve its title from the catalog.
  # The form's object must include CatalogRecordIdFormConcern.
  class CatalogRecordIdComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder]
    # @param container_classes [String, Array<String>] for the field, e.g., none within a has_many row
    def initialize(form:, label_classes: [], label_text: nil, hidden_label: false, mark_required: true, # rubocop:disable Metrics/ParameterLists
                   container_classes: 'my-field')
      @form = form
      @container_classes = container_classes
      @label_classes = label_classes
      @label_text = label_text
      @hidden_label = hidden_label
      @mark_required = mark_required
      super()
    end

    attr_reader :form, :label_classes, :hidden_label, :mark_required

    def container_classes
      merge_classes(@container_classes)
    end

    def label_text
      @label_text || t('edit.items.fields.catalog_record_id.label')
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
