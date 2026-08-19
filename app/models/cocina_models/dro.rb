# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina DRO object.
  class Dro < Base
    include CatalogLinksConcern
    include AccessConcern

    # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object to build this model from
    def self.build_from_cocina_object(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::DROWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::DROWithMetadata'
      end

      super
    end

    attribute :source_id, :string
    normalizes_whitespace :source_id
    validates :source_id, presence: true
    validates :source_id, format: { with: /\A.+:.+\z/ }

    attribute :barcode, :string
    normalizes_whitespace :barcode
    validate :validate_barcode

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

    def request_cocina_object
      # This is the minimal props to create a valid RequestDRO.
      # The rest will be filled in by the mutator.
      cocina_request_object = Cocina::Models.build_request(
        {
          type: content_type,
          identification: { sourceId: source_id },
          administrative: { hasAdminPolicy: admin_policy_druid },
          description: description_hash
        },
        validate: false
      )
      CocinaObjectMutators::DroMutator.call(cocina_object: cocina_request_object, cocina_model: self)
    end

    def viewing_direction_only_for_applicable_content_types
      return if viewing_direction.blank?
      return if Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS.include?(content_type)

      errors.add(:viewing_direction, 'is only valid for book and image content types')
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

    def match_embargo_access?(view:, download:, location: [nil])
      Array(view).include?(embargo_view) &&
        Array(download).include?(embargo_download) &&
        Array(location).include?(embargo_location)
    end

    def validate_barcode
      return if barcode.nil?
      return if Cocina::Models::Barcode.valid?(barcode)

      errors.add(:barcode, 'is not a valid barcode')
    end
  end
end
