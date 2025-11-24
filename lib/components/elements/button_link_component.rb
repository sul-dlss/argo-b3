# frozen_string_literal: true

module Elements
  # Component for a link styled as a button.
  class ButtonLinkComponent < ApplicationComponent
    def initialize(label:, path:, variant: nil, size: nil, classes: [], bordered: true, **link_attrs) # rubocop:disable Metrics/ParameterLists
      @label = label
      @path = path
      @classes = ComponentSupport::ButtonSupport.classes(variant:, size:, classes:, bordered:)
      @link_attrs = link_attrs
      super()
    end

    attr_reader :label, :path, :classes, :link_attrs

    def call
      link_to label, path, class: classes, role: 'button', **link_attrs
    end
  end
end
