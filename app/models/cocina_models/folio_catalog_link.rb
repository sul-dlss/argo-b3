# frozen_string_literal: true

module CocinaModels
  # Model for a Folio catalog link (catalog: 'folio').
  class FolioCatalogLink < Blanks::Base
    include NormalizationConcern
    include CatalogRecordIdConcern

    validates :catalog_record_id, presence: true
  end
end
