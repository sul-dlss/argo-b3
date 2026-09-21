# frozen_string_literal: true

module Searchers
  # Searcher for counting items and collections governed by an admin policy.
  class AdminPolicyObjectCounts
    Result = Struct.new(:item_count, :collection_count)

    def self.call(...)
      new(...).call
    end

    # @param admin_policy_druid [String]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @return [Result] counts for items and collections governed by the admin policy
    def initialize(admin_policy_druid:, user_scope:)
      @admin_policy_druid = admin_policy_druid
      @user_scope = user_scope
    end

    def call
      Result.new(
        item_count: count(object_type: 'item'),
        collection_count: count(object_type: 'collection')
      )
    end

    private

    attr_reader :admin_policy_druid, :user_scope

    def count(object_type:)
      QueryCount.call(query: "#{Search::Fields::APO_DRUID}:\"#{admin_policy_druid}\" AND " \
                             "#{Search::Fields::OBJECT_TYPES}:\"#{object_type}\"", user_scope:)
    end
  end
end
