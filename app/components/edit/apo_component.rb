# frozen_string_literal: true

module Edit
  # Component for rendering edit form for the governing APO
  class ApoComponent < ApplicationComponent
    def initialize(form:, options:, container_classes: [])
      @form = form
      @options = options
      @container_classes = container_classes
      super()
    end

    attr_reader :form, :options

    def container_classes
      merge_classes(@container_classes)
    end
  end
end
