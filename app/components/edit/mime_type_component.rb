# frozen_string_literal: true

module Edit
  # Component for selecting the MIME type of a file.
  # The user can select a common MIME type or enter another one.
  # The form's object must provide mime_type.
  class MimeTypeComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] a nested form builder for a ContentFileForm
    # @param label_text [String] the visually hidden label, which names the file (the field is in a table row)
    def initialize(form:, label_text:)
      @form = form
      @label_text = label_text
      super()
    end

    attr_reader :form, :label_text

    # Includes the current MIME type when it is not a common one, so that it remains selected.
    def options
      mime_type = form.object.mime_type
      return MimeTypes::COMMON if mime_type.blank? || MimeTypes::COMMON.include?(mime_type)

      [mime_type, *MimeTypes::COMMON]
    end
  end
end
