# frozen_string_literal: true

# Concern for the collection fields used by forms that support selecting collections.
module CollectionFormConcern
  extend ActiveSupport::Concern

  included do
    # Removes the blank value submitted by the multiple select.
    normalizes_array_compact_blank :collection_druids

    attribute :limit_collection_by_apo, :boolean, default: false
  end
end
