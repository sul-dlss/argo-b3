# frozen_string_literal: true

module Edit
  # Component for rendering edit form for project tags
  class ProjectTagComponent < ApplicationComponent
    include TagSuggestionsConcern

    # @param suggest [Boolean] whether to suggest existing project tags as the user types
    def initialize(form:, container_classes: [], suggest: false)
      @form = form
      @container_classes = container_classes
      @suggest = suggest
      super()
    end

    attr_reader :form

    def container_classes
      merge_classes(@container_classes)
    end

    def suggest?
      @suggest
    end

    def tag_type
      'project'
    end
  end
end
