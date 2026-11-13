# frozen_string_literal: true

module Edit
  # Component for rendering the version description field of a form that saves or deposits a version.
  # The form's object must have a version_description attribute (e.g., by including EditCocinaObjectFormConcern).
  class VersionDescriptionComponent < ApplicationComponent
    # @param help_text [String, nil] help text shown with the field
    # @param disabled [Boolean] true if the version description is fixed (e.g., set automatically for initial
    #   versions), so it is neither editable nor required
    def initialize(form:, container_classes: 'mb-3', label_classes: nil, help_text: nil, disabled: false)
      @form = form
      @container_classes = container_classes
      @label_classes = label_classes
      @help_text = help_text
      @disabled = disabled
      super()
    end

    # @return [Hash] the arguments for the text field, omitting those that are not set
    def text_field_args
      {
        form: @form,
        field_name: :version_description,
        label_text: t('edit.items.fields.version_description.label'),
        label_classes: @label_classes,
        label_mark_required: !@disabled,
        input_disabled: @disabled,
        help_text: @help_text,
        container_classes: @container_classes
      }.compact
    end
  end
end
