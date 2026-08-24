# frozen_string_literal: true

module Show
  # Component for displaying an object's embargo release date on the show page.
  class EmbargoBannerComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(release_date:, edit_path: nil)
      @release_date = release_date
      @edit_path = edit_path
      super()
    end

    def render?
      release_date.present?
    end

    def formatted_release_date
      format_datetime(release_date, format: :date_only)
    end

    private

    attr_reader :edit_path, :release_date
  end
end
