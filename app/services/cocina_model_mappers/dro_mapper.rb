# frozen_string_literal: true

module CocinaModelMappers
  # Mapper for a Cocina DRO to the attributes for a CocinaModels::Dro.
  class DroMapper < BaseMapper
    def call
      super.merge(
        access_view: cocina_object.access.view,
        access_download: cocina_object.access.download,
        access_location: cocina_object.access.location
      )
    end
  end
end
