# frozen_string_literal: true

module Layout
  # Component for a page's content container, with an optional breadcrumb, h1, and subtitle above the content.
  class ContainerComponent < ApplicationComponent
    renders_one :breadcrumb

    # @param heading [String, nil] The page's h1.
    # @param subtitle [String, nil] A line below the h1 (e.g., the object's title).
    # @param classes [Array<String>, String] Classes added to the container.
    # @param options [Hash] Other attributes of the container (e.g., data).
    def initialize(heading: nil, subtitle: nil, classes: [], **options)
      @heading = heading
      @subtitle = subtitle
      @classes = classes
      @options = options
      super()
    end

    attr_reader :heading, :subtitle, :options

    def classes
      merge_classes('container py-2', @classes)
    end

    def heading_classes
      subtitle ? 'mb-2' : 'mb-3'
    end
  end
end
