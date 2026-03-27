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

    private

    def model_attrs_for(cocina_object)
      CocinaModelMappers::CollectionMapper.call(cocina_object:)
    end

    def mutated_cocina_object
      CocinaObjectMutators::CollectionMutator.call(cocina_object: previous_cocina_object, cocina_model: self)
    end
  end
end
