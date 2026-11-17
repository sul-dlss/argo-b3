# frozen_string_literal: true

module Elements
  # Component for a titled list of action buttons with optional help text.
  class ButtonListComponent < ApplicationComponent
    # A button with its own rules (e.g., Show::ExtractTextButtonComponent) passes its component_class.
    renders_many :buttons,
                 lambda { |component_class: SdrViewComponents::Elements::ButtonFormComponent, classes: 'mb-2', **args|
                   component_class.new(classes:, **args)
                 }

    def initialize(title: nil, help_text: nil, classes: [])
      @title = title
      @help_text = help_text
      @classes = classes
      super()
    end

    attr_reader :title, :help_text, :disabled

    def render?
      buttons.any?
    end

    def classes
      merge_classes(@classes)
    end
  end
end
