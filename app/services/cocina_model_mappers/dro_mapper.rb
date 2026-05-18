# frozen_string_literal: true

module CocinaModelMappers
  # Mapper for a Cocina DRO to the attributes for a CocinaModels::Dro.
  class DroMapper < BaseMapper
    def call # rubocop:disable Metrics/AbcSize
      super.merge(
        access_view: cocina_object.access.view,
        access_download: cocina_object.access.download,
        access_location: cocina_object.access.location,
        embargo_release_date: cocina_object.access.embargo&.releaseDate,
        embargo_view: cocina_object.access.embargo&.view,
        embargo_download: cocina_object.access.embargo&.download,
        embargo_location: cocina_object.access.embargo&.location
      )
    end
  end
end
