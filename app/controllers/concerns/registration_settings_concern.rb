# frozen_string_literal: true

# Concern for controllers whose registration form can be prefilled with the settings of an existing item,
# given by the from_druid param ("Copy registration settings from" on the item show page).
module RegistrationSettingsConcern
  extend ActiveSupport::Concern

  private

  # @return [RegistrationSettings, nil] the settings of the from_druid item, or nil when there is none
  def registration_settings
    return if params[:from_druid].blank?

    @registration_settings ||= begin
      cocina_object = Sdr::Repository.find(druid: params.expect(:from_druid))
      RegistrationSettings.new(cocina_object:)
    end
  end

  # A prefilled form keeps the copied rights rather than having the APO's defaults applied when it is displayed.
  # @return [Boolean]
  def apply_apo_defaults_on_new?
    registration_settings.nil?
  end
end
