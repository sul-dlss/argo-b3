# frozen_string_literal: true

module BulkActions
  # Form for update collections bulk action.
  class ManageCollectionsForm < BasicForm
    attribute :collection_druids, array: true, default: []
    # The multiple select submits a blank value alongside the selected collections.
    normalizes_array_compact_blank :collection_druids
  end
end
