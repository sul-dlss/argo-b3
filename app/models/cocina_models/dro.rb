# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina DRO object.
  class Dro < Base
    include CatalogLinksConcern

    # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object to initialize this model with
    def initialize(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::DROWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::DROWithMetadata'
      end

      super
    end

    attribute :source_id, :string
    validates :source_id, presence: true
    validates :source_id, format: { with: /\A.+:.+\z/ }

    attribute :barcode, :string
    validate :validate_barcode

    # Access fields
    attribute :use_and_reproduction_statement, :string
    attribute :license, :string
    attribute :copyright, :string
    attribute :access_view, :string
    attribute :access_download, :string
    attribute :access_location, :string
    # Note that the error is reported on :access, not :access_view, :access_download, or :access_location
    validate :validate_access

    # Embargo fields
    attribute :embargo_release_date, :datetime
    attribute :embargo_view, :string
    attribute :embargo_download, :string
    attribute :embargo_location, :string
    # Note that the error is reported on :embargo_access, not the individual embargo fields
    validate :validate_embargo_access, if: :embargo_release_date?

    # Content type and viewing direction fields
    attribute :content_type, :string
    attribute :viewing_direction, :string
    validates :content_type, presence: true
    validates :content_type, inclusion: { in: Cocina::Models::DRO::TYPES }
    validates :viewing_direction, inclusion: { in: Constants::VIEWING_DIRECTIONS }, allow_nil: true
    validate :viewing_direction_only_for_applicable_content_types

    def dark_access?
      match_access?(view: 'dark', download: 'none')
    end

    def citation_only_access?
      match_access?(view: 'citation-only', download: 'none')
    end

    def location_based_access?
      match_access?(view: 'location-based', download: %w[location-based none], location: Constants::ACCESS_LOCATIONS)
    end

    def location_based_download_access?
      match_access?(view: %w[stanford world], download: 'location-based', location: Constants::ACCESS_LOCATIONS)
    end

    def stanford_access?
      match_access?(view: 'stanford', download: 'stanford')
    end

    def world_access?
      match_access?(view: 'world', download: %w[world stanford none])
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

    def model_attrs_for(cocina_object)
      CocinaModelMappers::DroMapper.call(cocina_object:)
    end

    def mutated_cocina_object
      CocinaObjectMutators::DroMutator.call(cocina_object: previous_cocina_object, cocina_model: self)
    end

    def viewing_direction_only_for_applicable_content_types
      return if viewing_direction.blank?
      return if Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS.include?(content_type)

      errors.add(:viewing_direction, 'is only valid for book and image content types')
    end

    def validate_access
      return if dark_access? ||
                citation_only_access? ||
                location_based_access? ||
                location_based_download_access? ||
                stanford_access? ||
                world_access?

      errors.add(:access, 'is not valid')
    end

    def validate_embargo_access
      return if embargo_dark_access? ||
                embargo_citation_only_access? ||
                embargo_location_based_access? ||
                embargo_location_based_download_access? ||
                embargo_stanford_access? ||
                embargo_world_access?

      errors.add(:embargo_access, 'is not valid')
    end

    def match_access?(view:, download:, location: [nil])
      Array(view).include?(access_view) &&
        Array(download).include?(access_download) &&
        Array(location).include?(access_location)
    end

    def match_embargo_access?(view:, download:, location: [nil])
      Array(view).include?(embargo_view) &&
        Array(download).include?(embargo_download) &&
        Array(location).include?(embargo_location)
    end

    BARCODE_FORMATS = [
      /^2050[0-9]{7}$/,
      /^245[0-9]{8}$/,
      /^[0-9]+-[0-9]+$/,
      /^36105[0-9]{9}$/,
      /^405[0-9]+$/
    ].freeze
    private_constant :BARCODE_FORMATS

    def validate_barcode
      return if barcode.blank?
      return if BARCODE_FORMATS.any? { |pattern| pattern.match?(barcode) }

      errors.add(:barcode, 'is not a valid barcode')
    end
  end
end
