# frozen_string_literal: true

module Elements
  # Renders the numbered steps of a multi-step process, each with its status (Elements::ProgressStepperStepComponent).
  # Not specific to any process, so it could move to SDR View Components.
  class ProgressStepperComponent < ApplicationComponent
    # @param label [String] the accessible name of the list of steps
    # @param steps [Array<Hash>] each step's label (String) and status (:completed, :in_progress, or :pending),
    #   in order
    def initialize(label:, steps:, classes: nil)
      @label = label
      @steps = steps
      @classes = classes
      super()
    end

    attr_reader :label, :steps

    def classes
      merge_classes('progress-stepper', @classes)
    end
  end
end
