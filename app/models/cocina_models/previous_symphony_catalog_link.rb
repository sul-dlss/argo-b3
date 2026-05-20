# frozen_string_literal: true

module CocinaModels
  # Model for a previous Symphony catalog link (catalog: 'previous symphony').
  class PreviousSymphonyCatalogLink < CatalogLinkBase
    def catalog = 'previous symphony'

    validates :catalog_record_id, format: { with: /\A\d+\z/ }, allow_blank: true
  end
end
