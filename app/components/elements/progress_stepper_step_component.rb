# frozen_string_literal: true

module Elements
  # Renders one numbered step of an Elements::ProgressStepperComponent, with its status.
  class ProgressStepperStepComponent < ApplicationComponent
    # @param number [Integer] the step's position, starting at 1
    # @param label [String]
    # @param status [Symbol] :completed, :in_progress, or :pending
    def initialize(number:, label:, status:)
      @number = number
      @label = label
      @status = status
      super()
    end

    attr_reader :number, :label

    def classes
      merge_classes('progress-stepper-step', "progress-stepper-step-#{@status.to_s.dasherize}")
    end

    # The step being worked on is the current step.
    def aria_current
      'step' if @status == :in_progress
    end

    def completed?
      @status == :completed
    end

    def status_text
      t("progress_stepper.statuses.#{@status}")
    end
  end
end
