# frozen_string_literal: true

module BulkActions
  # Form for update collections bulk action.
  class ManageCollectionsForm < BasicForm
    attribute :collection_druids, array: true, default: []
    # The multiple select submits a blank value alongside the selected collections.
    normalizes_array_compact_blank :collection_druids

    # Title and druid pairs for the selected collections, so the select can be rebuilt after a validation error.
    def collection_options
      return [] if collection_druids.empty?

      collection_titles = Searchers::CollectionListByDruid.call(druids: collection_druids).to_h(&:reverse)
      collection_druids.map do |druid|
        [collection_titles[druid] || DruidSupport.bare_druid_from(druid), druid]
      end
    end
  end
end
