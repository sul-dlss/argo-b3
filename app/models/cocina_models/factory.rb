# frozen_string_literal: true

module CocinaModels
  # Factory for creating Cocina models from Cocina objects.
  class Factory
    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::DROLite,Cocina::Models::CollectionLite]
    # @return [CocinaModels::Dro, CocinaModels::Collection] the created model
    # @raise [ArgumentError] if the cocina_object is not a DRO or Collection with metadata
    def self.build(cocina_object)
      case cocina_object
      when Cocina::Models::DROWithMetadata, Cocina::Models::DROLite
        Dro.new(cocina_object)
      when Cocina::Models::CollectionWithMetadata, Cocina::Models::CollectionLite
        Collection.new(cocina_object)
      when Cocina::Models::AdminPolicyWithMetadata, Cocina::Models::AdminPolicyLite
        AdminPolicy.new(cocina_object)
      else
        raise ArgumentError, 'Unexpected cocina object type'
      end
    end
  end
end
