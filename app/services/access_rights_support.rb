# frozen_string_literal: true

# Methods for determining the valid combinations of view, download, and location access rights.
class AccessRightsSupport
  def self.dark?(view:, download:, location:)
    match?(view:, download:, location:, allowed_views: 'dark', allowed_downloads: 'none')
  end

  def self.citation_only?(view:, download:, location:)
    match?(view:, download:, location:, allowed_views: 'citation-only', allowed_downloads: 'none')
  end

  def self.location_based?(view:, download:, location:)
    match?(view:, download:, location:, allowed_views: 'location-based', allowed_downloads: %w[location-based none],
           allowed_locations: Constants::ACCESS_LOCATIONS)
  end

  def self.location_based_download?(view:, download:, location:)
    match?(view:, download:, location:, allowed_views: %w[stanford world], allowed_downloads: 'location-based',
           allowed_locations: Constants::ACCESS_LOCATIONS)
  end

  def self.stanford?(view:, download:, location:)
    match?(view:, download:, location:, allowed_views: 'stanford', allowed_downloads: 'stanford')
  end

  def self.world?(view:, download:, location:)
    match?(view:, download:, location:, allowed_views: 'world', allowed_downloads: %w[world stanford none])
  end

  # @param citation_only [Boolean] false if citation-only access is not allowed (e.g., for files)
  # @return [Boolean] true if the combination of access rights is valid
  def self.valid?(view:, download:, location:, citation_only: true)
    return true if citation_only && citation_only?(view:, download:, location:)

    %i[dark? location_based? location_based_download? stanford? world?].any? do |access_method|
      public_send(access_method, view:, download:, location:)
    end
  end

  # Location must be nil unless allowed_locations are provided.
  def self.match?(view:, download:, location:, allowed_views:, allowed_downloads:, allowed_locations: [nil]) # rubocop:disable Metrics/ParameterLists
    Array(allowed_views).include?(view) &&
      Array(allowed_downloads).include?(download) &&
      Array(allowed_locations).include?(location)
  end
  private_class_method :match?
end
