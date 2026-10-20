# frozen_string_literal: true

module Edit
  # Button that structures the files of a content, with a spinner shown while structuring (see .structure-action).
  class StructureButtonComponent < ApplicationComponent
    # @param commit [String] ContentStructureController::STRUCTURE_VALUE or APPEND_VALUE
    # @param populator [String] the name of the populator
    # @param content_type [String, nil] the selected content type, which may not have been saved yet
    def initialize(label:, commit:, populator:, content_token:, content_type:, classes: nil) # rubocop:disable Metrics/ParameterLists
      @label = label
      @commit = commit
      @populator = populator
      @content_token = content_token
      @content_type = content_type
      @classes = classes
      super()
    end

    attr_reader :label, :commit, :populator, :content_token, :content_type

    def classes
      merge_classes('structure-action', @classes)
    end

    # While structuring, the resources' actions are disabled (see structure_actions_controller.js).
    def data
      { action: 'turbo:submit-start->structure-actions#disable turbo:submit-end->structure-actions#enable' }
    end
  end
end
