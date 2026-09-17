# frozen_string_literal: true

module Searchers
  # Searcher for counting items in a collection.
  class CollectionItemCount
    def self.call(...)
      new(...).call
    end

    # @param collection_druid [String]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @return [Integer] number of items in the collection
    def initialize(collection_druid:, user_scope:)
      @collection_druid = collection_druid
      @user_scope = user_scope
    end

    def call
      QueryCount.call(query: "#{Search::Fields::COLLECTION_DRUIDS}:\"#{collection_druid}\"", user_scope:)
    end

    private

    attr_reader :collection_druid, :user_scope
  end
end
