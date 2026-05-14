# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina DRO object.
  class Dro < Base
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

    # Access fields
    attribute :use_and_reproduction_statement, :string
    attribute :license, :string
    attribute :copyright, :string
    attribute :access_view, :string
    attribute :access_download, :string
    attribute :access_location, :string
    # Note that the error is reported on :access, not :access_view, :access_download, or :access_location
    validate :validate_access

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
      match_access?(view: 'world', download: %w[none stanford world])
    end

    private

    def model_attrs_for(cocina_object)
      CocinaModelMappers::DroMapper.call(cocina_object:)
    end

    def mutated_cocina_object
      CocinaObjectMutators::DroMutator.call(cocina_object: previous_cocina_object, cocina_model: self)
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

    def match_access?(view:, download:, location: [nil])
      Array(view).include?(access_view) &&
        Array(download).include?(access_download) &&
        Array(location).include?(access_location)
    end
  end
end
