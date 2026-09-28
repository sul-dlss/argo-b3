# frozen_string_literal: true

module CocinaModels
  # Concern for handling collection membership in Cocina models.
  module CollectionConcern
    extend ActiveSupport::Concern

    included do
      attribute :collection_druids, array: true, default: -> { [] }
    end
  end
end
