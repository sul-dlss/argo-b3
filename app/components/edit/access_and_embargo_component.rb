# frozen_string_literal: true

module Edit
  # Component for rendering edit form for access settings, including embargo
  # The form's object must include CocinaModels::AccessConcern, CocinaModels::EmbargoConcern, and EmbargoFormConcern,
  # and FileAccessFormConcern when showing the overwrite file access checkbox.
  class AccessAndEmbargoComponent < ApplicationComponent
    # @param apo_defaults [Boolean] true to show (and apply) the selected APO's default access, using the
    #   apo-defaults Stimulus controller
    # @param overwrite_file_access [Boolean] true to show the checkbox for applying the access to the files
    def initialize(form:, apo_defaults: false, overwrite_file_access: false)
      @form = form
      @apo_defaults = apo_defaults
      @overwrite_file_access = overwrite_file_access
      super()
    end

    attr_reader :form

    def overwrite_file_access?
      @overwrite_file_access
    end

    # @param group [String] the apo-defaults group of the access fields
    # @return [String, nil] the group, if showing APO defaults
    def apo_defaults_group(group)
      group if @apo_defaults
    end

    # A date input only accepts a date (YYYY-MM-DD), so it would otherwise discard the release date, which is a
    # datetime. The date is in the application time zone (UTC), in which a submitted date is cast to a datetime,
    # so that saving the form does not change the date.
    # @return [String, nil]
    def embargo_release_date_value
      form.object.embargo_release_date&.to_date&.iso8601
    end
  end
end
