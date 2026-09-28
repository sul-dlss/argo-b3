# frozen_string_literal: true

module Edit
  # Component for rendering edit form for content type
  class ContentTypeComponent < ApplicationComponent
    def initialize(form:, container_classes: [], input_data: {})
      @form = form
      @container_classes = container_classes
      @input_data = input_data
      super()
    end

    attr_reader :form, :input_data

    def container_classes
      merge_classes(@container_classes)
    end
  end
end
