# frozen_string_literal: true

module Edit
  # Component for rendering the administrative (publish / preserve) radio buttons for a file.
  class FileAdministrativeComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] a form builder for a ContentFileForm
    def initialize(form:, container_classes: [])
      @form = form
      @container_classes = container_classes
      super()
    end

    attr_reader :form

    def container_classes
      merge_classes(@container_classes)
    end

    def label_text_for(administrative_option)
      t("edit.content_file_sets.fields.content_files.administrative.options.#{administrative_option}")
    end
  end
end
