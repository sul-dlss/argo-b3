# frozen_string_literal: true

module CocinaModels
  # Concern for handling embargo in Cocina models.
  module EmbargoConcern
    extend ActiveSupport::Concern

    included do
      attribute :embargo_release_date, :datetime
      attribute :embargo_view, :string
      attribute :embargo_download, :string
      attribute :embargo_location, :string
      # Note that the error is reported on :embargo_access, not the individual embargo fields
      validate :validate_embargo_access, if: :embargo_release_date?
    end

    def embargo_dark_access?
      match_embargo_access?(view: 'dark', download: 'none')
    end

    def embargo_citation_only_access?
      match_embargo_access?(view: 'citation-only', download: 'none')
    end

    def embargo_location_based_access?
      match_embargo_access?(view: 'location-based', download: %w[location-based none], location: Constants::ACCESS_LOCATIONS)
    end

    def embargo_location_based_download_access?
      match_embargo_access?(view: %w[stanford world], download: 'location-based', location: Constants::ACCESS_LOCATIONS)
    end

    def embargo_stanford_access?
      match_embargo_access?(view: 'stanford', download: 'stanford')
    end

    def embargo_world_access?
      match_embargo_access?(view: 'world', download: %w[world stanford none])
    end

    def embargo_release_date?
      embargo_release_date.present?
    end

    private

    def validate_embargo_access
      return if embargo_dark_access? ||
                embargo_citation_only_access? ||
                embargo_location_based_access? ||
                embargo_location_based_download_access? ||
                embargo_stanford_access? ||
                embargo_world_access?

      errors.add(:embargo_access, 'is not valid')
    end

    def match_embargo_access?(view:, download:, location: [nil])
      Array(view).include?(embargo_view) &&
        Array(download).include?(embargo_download) &&
        Array(location).include?(embargo_location)
    end
  end
end
