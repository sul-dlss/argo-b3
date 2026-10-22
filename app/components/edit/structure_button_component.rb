# frozen_string_literal: true

module Edit
  # Button that structures the files of a content, with a spinner shown while structuring (see .spinner-on-submit).
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
      merge_classes('structure-action spinner-on-submit', @classes)
    end
  end
end
