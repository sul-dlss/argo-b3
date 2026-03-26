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

    private

    def model_attrs_for(cocina_object)
      CocinaModelMappers::DroMapper.call(cocina_object:)
    end

    def mutated_cocina_object
      CocinaObjectMutators::DroMutator.call(cocina_object: previous_cocina_object, cocina_model: self)
    end
  end
end
