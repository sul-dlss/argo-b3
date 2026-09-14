# frozen_string_literal: true

module Edit
  # Component for rendering edit form for other tags (not project or ticket)
  class OtherTagComponent < ApplicationComponent
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
