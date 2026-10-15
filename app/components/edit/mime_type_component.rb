# frozen_string_literal: true

module Edit
  # Component for selecting the MIME type of a file.
  # The user can select a common MIME type or enter another one.
  class MimeTypeComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] a nested form builder for a ContentFileForm
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    # Includes the current MIME type when it is not a common one, so that it remains selected.
    def options
      mime_type = form.object.mime_type
      return MimeTypes::COMMON if mime_type.blank? || MimeTypes::COMMON.include?(mime_type)

      [mime_type, *MimeTypes::COMMON]
    end
  end
end
