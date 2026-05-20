# frozen_string_literal: true

module CocinaModels
  # Base class for catalog link models (symphony and folio variants).
  class CatalogLinkBase < Blanks::Base
    attribute :catalog_record_id, :string
    attribute :refresh, :boolean, default: false

    validates :catalog_record_id, presence: true
  end
end
