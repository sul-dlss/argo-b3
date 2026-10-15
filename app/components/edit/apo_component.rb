# frozen_string_literal: true

module Edit
  # Component for rendering edit form for the governing APO
  class ApoComponent < ApplicationComponent
    # @param options [Array<Array(String, String)>] the title and druid of each APO
    # @param apo_defaults [Boolean] true to apply the selected APO's defaults to the rights fields, using the
    #   apo-defaults Stimulus controller
    def initialize(form:, options:, container_classes: [], apo_defaults: false)
      @form = form
      @options = options
      @container_classes = container_classes
      @apo_defaults = apo_defaults
      super()
    end

    attr_reader :form

    def container_classes
      merge_classes(@container_classes)
    end

    # Each option has the URL of the APO's defaults when applying APO defaults.
    def options
      return @options unless @apo_defaults

      @options.map { |title, druid| [title, druid, { data: { apo_defaults_url: helpers.apo_default_path(druid) } }] }
    end

    def input_data
      @apo_defaults ? { apo_defaults_target: 'apo', action: 'apo-defaults#apply' } : {}
    end
  end
end
