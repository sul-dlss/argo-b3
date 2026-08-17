# frozen_string_literal: true

module Elements
  # Component for a titled list of action buttons with optional help text.
  class ButtonListComponent < ApplicationComponent
    renders_many :buttons, ->(classes: 'mb-2', **args) { SdrViewComponents::Elements::ButtonFormComponent.new(classes:, **args) }

    def initialize(title:, help_text: nil, classes: [])
      @title = title
      @help_text = help_text
      @classes = classes
      super()
    end

    attr_reader :title, :help_text

    def render?
      buttons.any?
    end

    def classes
      merge_classes(@classes)
    end
  end
end
