# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina Collection object.
  class Collection < Base
    # @param cocina_object [Cocina::Models::CollectionWithMetadata] the Cocina object to initialize this model with
    def initialize(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::CollectionWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::CollectionWithMetadata'
      end

      super
    end

    has_many :symphony_catalog_links, class_name: 'CocinaModels::SymphonyCatalogLink', allow_destroy: true
    has_many :previous_symphony_catalog_links, class_name: 'CocinaModels::PreviousSymphonyCatalogLink',
                                               allow_destroy: true
    has_many :folio_catalog_links, class_name: 'CocinaModels::FolioCatalogLink', allow_destroy: true
    has_many :previous_folio_catalog_links, class_name: 'CocinaModels::PreviousFolioCatalogLink', allow_destroy: true

    attribute :source_id, :string
    validates :source_id, presence: true
    validates :source_id, format: { with: /\A.+:.+\z/ }

    # Access fields
    attribute :use_and_reproduction_statement, :string
    attribute :license, :string
    attribute :copyright, :string
    attribute :access_view, :string
    validates :access_view, inclusion: { in: %w[world dark] }, allow_nil: false

    private

    def model_attrs_for(cocina_object)
      CocinaModelMappers::CollectionMapper.call(cocina_object:)
    end

    def mutated_cocina_object
      CocinaObjectMutators::CollectionMutator.call(cocina_object: previous_cocina_object, cocina_model: self)
    end
  end
end
