# frozen_string_literal: true

module Cocina
  # Factory for creating Cocina models from Cocina objects.
  class Factory
    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata]
    # @return [Cocina::Dro, Cocina::Collection] the created model
    # @raise [ArgumentError] if the cocina_object is not a DRO or Collection with metadata
    def self.build(cocina_object)
      case cocina_object
      when Cocina::Models::DROWithMetadata
        Dro.new(cocina_object)
      when Cocina::Models::CollectionWithMetadata
        Collection.new(cocina_object)
      else
        raise ArgumentError, 'Expected a Cocina::Models::DROWithMetadata or Cocina::Models::CollectionWithMetadata'
      end
    end
  end
end
