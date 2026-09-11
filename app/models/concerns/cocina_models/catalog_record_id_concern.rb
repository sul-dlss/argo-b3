# frozen_string_literal: true

module CocinaModels
  # Concern for handling catalog record id (FOLIO Instance HRID) in Cocina models.
  module CatalogRecordIdConcern
    extend ActiveSupport::Concern

    included do
      attribute :catalog_record_id, :string
      normalizes_whitespace :catalog_record_id
      validates :catalog_record_id, format: { with: /\A(a\d+|L\d+|in\d+)\z/ }, allow_blank: true
    end
  end
end
