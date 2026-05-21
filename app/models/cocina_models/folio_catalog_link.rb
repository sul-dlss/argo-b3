# frozen_string_literal: true

module CocinaModels
  # Model for a Folio catalog link (catalog: 'folio').
  class FolioCatalogLink < Blanks::Base
    attribute :catalog_record_id, :string
    validates :catalog_record_id, format: { with: /\A(a\d+|L\d+|in\d+)\z/ }, allow_blank: false
  end
end
