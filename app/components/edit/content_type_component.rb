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

    # The registration content types, plus the current content type if it is not one of them,
    # so that an existing content type is not changed by the select defaulting to another option.
    def options
      content_type = form.object&.content_type
      if content_type.blank? || Constants::REGISTRATION_CONTENT_TYPES.value?(content_type)
        return Constants::REGISTRATION_CONTENT_TYPES
      end

      Constants::REGISTRATION_CONTENT_TYPES.merge(UriSupport.last(uri: content_type) => content_type)
    end
  end
end
