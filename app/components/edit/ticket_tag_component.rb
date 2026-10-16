# frozen_string_literal: true

module Edit
  # Component for rendering edit form for ticket tags
  class TicketTagComponent < ApplicationComponent
    include TagSuggestionsConcern

    # @param suggest [Boolean] whether to suggest existing ticket tags as the user types
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
      'ticket'
    end
  end
end
