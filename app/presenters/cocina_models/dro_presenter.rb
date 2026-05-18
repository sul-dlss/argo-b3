# frozen_string_literal: true

module CocinaModels
  # Presenter for a Dro cocina model.
  # It will delegate to the Dro model.
  # Initialize with: CocinaModels::DroPresenter.new(dro),
  # where dro is a CocinaModels::Dro.
  class DroPresenter < BasePresenter
    include ApplicationHelper

    def display_access_rights
      display_view = display_view(view: access_view, location: access_location)
      display_download = display_download(download: access_download, location: access_location)
      "#{display_view}, #{display_download}"
    end

    def embargo
      return unless embargo_release_date?

      display_view = display_view(view: embargo_view, location: embargo_location)
      display_download = display_download(download: embargo_download, location: embargo_location)
      "#{format_datetime(embargo_release_date)} - #{display_view}, #{display_download}"
    end

    private

    def display_view(view:, location:)
      display = "View: #{humanize_access_value(view)}"
      return display unless view == 'location-based'

      display + display_location(location:)
    end

    def display_download(download:, location:)
      display = "Download: #{humanize_access_value(download)}"
      return display unless download == 'location-based'

      display + display_location(location:)
    end

    def display_location(location:)
      " (#{location})"
    end
  end
end
