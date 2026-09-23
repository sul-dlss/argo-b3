# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina Collection object.
  class Collection < Base
    include CatalogLinksConcern
    include SourceIdConcern

    # @param cocina_object [Cocina::Models::CollectionWithMetadata] the Cocina object to build this model from
    def self.build_from_cocina_object(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::CollectionWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::CollectionWithMetadata'
      end

      super
    end

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

    def request_cocina_object
      # This is the minimal props to create a valid RequestCollection.
      # The rest will be filled in by the mutator.
      cocina_request_object = Cocina::Models.build_request(
        {
          type: Cocina::Models::ObjectType.collection,
          administrative: { hasAdminPolicy: apo_druid },
          description: description_hash
        },
        validate: false
      )
      CocinaObjectMutators::CollectionMutator.call(cocina_object: cocina_request_object, cocina_model: self)
    end
  end
end
