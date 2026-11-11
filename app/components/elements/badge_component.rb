# frozen_string_literal: true

module Elements
  # Uppercase pill badge, e.g., an object type or "Read only". Candidate to move into SDR View Components.
  class BadgeComponent < ApplicationComponent
    # Object-type badges are bold at fs-5 or larger, so their colors need only meet the large-text contrast ratio.
    VARIANT_CLASSES = {
      object_type: 'object-type-bg fw-bold',
      status: 'status-badge fw-semibold border border-dark'
    }.freeze
    SIZE_CLASSES = { large: 'fs-4', medium: 'fs-5' }.freeze

    # @param label [String] text of the badge
    # @param variant [Symbol] :object_type (colored by the enclosing object-type-* class) or :status
    # @param size [Symbol] :large or :medium
    # @param tag [Symbol] element to render, e.g., :div where the badge is a block
    # @param classes [String, nil] additional space-separated classes, e.g., for layout
    def initialize(label:, variant:, size:, tag: :span, classes: nil)
      @label = label
      @variant_classes = VARIANT_CLASSES.fetch(variant)
      @size_classes = SIZE_CLASSES.fetch(size)
      @tag = tag
      @classes = classes
      super()
    end

    def call
      content_tag(@tag, @label,
                  class: merge_classes('text-uppercase rounded-pill', @variant_classes, @size_classes, @classes))
    end
  end
end
