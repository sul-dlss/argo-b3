# frozen_string_literal: true

module CocinaModelMappers
  # Mapper for a Cocina Collection to the attributes for a CocinaModels::Collection.
  class CollectionMapper < BaseMapper
    def call
      super.merge(
        access_view: cocina_object.access.view
      )
    end
  end
end
