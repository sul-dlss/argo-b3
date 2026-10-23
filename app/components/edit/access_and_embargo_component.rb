# frozen_string_literal: true

module Edit
  # Component for rendering edit form for access settings, including embargo
  # The form's object must include CocinaModels::AccessConcern, CocinaModels::EmbargoConcern, and EmbargoFormConcern.
  class AccessAndEmbargoComponent < ApplicationComponent
    # @param apo_defaults [Boolean] true to show (and apply) the selected APO's default access, using the
    #   apo-defaults Stimulus controller
    def initialize(form:, apo_defaults: false)
      @form = form
      @apo_defaults = apo_defaults
      super()
    end

    attr_reader :form

    # @param group [String] the apo-defaults group of the access fields
    # @return [String, nil] the group, if showing APO defaults
    def apo_defaults_group(group)
      group if @apo_defaults
    end
  end
end
