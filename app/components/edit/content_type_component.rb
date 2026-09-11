# frozen_string_literal: true

module Edit
  # Component for rendering edit form for content type
  class ContentTypeComponent < ApplicationComponent
    def initialize(form:, container_classes: [])
      @form = form
      @container_classes = container_classes
      super()
    end

    attr_reader :form

    def container_classes
      merge_classes(@container_classes)
    end
  end
end
