# frozen_string_literal: true

module CocinaModels
  # Presenter for a Dro cocina model.
  # It will delegate to the Dro model.
  # Initialize with: CocinaModels::DroPresenter.new(dro),
  # where dro is a CocinaModels::Dro.
  class DroPresenter < BasePresenter
    def display_access_rights
      "#{display_access_view}, #{display_access_download}"
    end

    private

    def display_access_view
      display = "View: #{humanize_access_value(access_view)}"
      return display unless location_based_access?

      display + display_access_location
    end

    def display_access_download
      display = "Download: #{humanize_access_value(access_download)}"
      return display unless location_based_download_access?

      display + display_access_location
    end

    def display_access_location
      " (#{access_location})"
    end
  end
end
