# frozen_string_literal: true

module Searchers
  # Searcher for counting items in a collection.
  class CollectionItemCount
    def self.call(...)
      new(...).call
    end

    # @param collection_druid [String]
    # @return [Integer] number of items in the collection
    def initialize(collection_druid:)
      @collection_druid = collection_druid
    end

    def call
      QueryCount.call(query: "#{Search::Fields::COLLECTION_DRUIDS}:\"#{collection_druid}\"")
    end

    private

    attr_reader :collection_druid
  end
end
