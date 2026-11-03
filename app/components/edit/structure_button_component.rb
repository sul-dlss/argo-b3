# frozen_string_literal: true

module Edit
  # Button that structures the files of a content, with a spinner shown while structuring (see .spinner-on-submit).
  class StructureButtonComponent < ApplicationComponent
    # @param commit [String] ContentStructureController::STRUCTURE_VALUE or APPEND_VALUE
    # @param populator [String] the name of the populator
    # @param content_type [String, nil] the selected content type, which may not have been saved yet
    # @param selected_access [Hash] the selected access (see ContentsItemForm::ACCESS_PARAMS), which may not have been
    #   saved yet
    def initialize(label:, commit:, populator:, content_token:, content_type:, selected_access:, classes: nil) # rubocop:disable Metrics/ParameterLists
      @label = label
      @commit = commit
      @populator = populator
      @content_token = content_token
      @content_type = content_type
      @selected_access = selected_access
      @classes = classes
      super()
    end

    attr_reader :label, :commit, :populator, :content_token

    # Omits the selected access when there is none, since an empty param is not a hash of access.
    def params
      { commit:, populator:, content_type: @content_type,
        ContentsItemForm.model_name.param_key => @selected_access.presence }.compact
    end

    def classes
      merge_classes('structure-action spinner-on-submit', @classes)
    end
  end
end
