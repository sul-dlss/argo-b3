# frozen_string_literal: true

module Edit
  # Component for rendering edit form for the governing APO
  # The form's object must include CocinaModels::ApoConcern.
  class ApoComponent < ApplicationComponent
    # @param options [Array<Array(String, String)>] the title and druid of each APO
    # @param apo_defaults [Boolean] true to apply the selected APO's defaults to the rights fields, using the
    #   apo-defaults Stimulus controller
    # @param apply_defaults_button [Boolean] true to apply the APO defaults only when the user clicks a button
    #   next to the select, rather than whenever an APO is selected (requires apo_defaults)
    def initialize(form:, options:, container_classes: [], apo_defaults: false, apply_defaults_button: false)
      @form = form
      @options = options
      @container_classes = container_classes
      @apo_defaults = apo_defaults
      @apply_defaults_button = apo_defaults && apply_defaults_button
      super()
    end

    attr_reader :form

    def container_classes
      merge_classes(@container_classes)
    end

    def apply_defaults_button?
      @apply_defaults_button
    end

    # Each option has the URL of the APO's defaults when applying APO defaults.
    def options
      return @options unless @apo_defaults

      @options.map { |title, druid| [title, druid, { data: { apo_defaults_url: helpers.apo_default_path(druid) } }] }
    end

    # With the apply defaults button, selecting an APO only shows its defaults, without applying them.
    def input_data
      return {} unless @apo_defaults

      { apo_defaults_target: 'apo', action: apply_defaults_button? ? 'apo-defaults#refresh' : 'apo-defaults#apply' }
    end

    def input_aria
      SdrViewComponents::Forms::InvalidFeedbackSupport.arias_for(field_name: :apo_druid, form:).merge(required: true)
    end
  end
end
