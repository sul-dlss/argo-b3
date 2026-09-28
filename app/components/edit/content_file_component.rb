# frozen_string_literal: true

module Edit
  # Component for editing a file within a file set (resource).
  class ContentFileComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] a nested form builder for a ContentFileForm
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    delegate :filepath, to: :content_file_form

    def content_file_form
      form.object
    end
  end
end
