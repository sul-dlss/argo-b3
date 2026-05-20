# frozen_string_literal: true

module CocinaModels
  # Model for a Symphony catalog link (catalog: 'symphony').
  class SymphonyCatalogLink < CatalogLinkBase
    def catalog = 'symphony'

    validates :catalog_record_id, format: { with: /\A\d+\z/ }, allow_blank: true
  end
end
