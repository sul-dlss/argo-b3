# frozen_string_literal: true

module Search
  # Restricts the Solr results using the same target rules as ObjectPolicy so that search results
  # match the current user's view/edit permissions: ObjectPolicy#show? by default, or ObjectPolicy#edit? when editable.
  class PermissionFilter
    TARGET_FIELDS = [Fields::ID, Fields::COLLECTION_DRUIDS, Fields::APO_DRUID].freeze
    MATCH_NONE_FILTER = '(*:* AND NOT *:*)'

    def self.call(...)
      new(...).call
    end

    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @param editable [Boolean] when true, limits to the objects the user can edit rather than read
    def initialize(user_scope:, editable: false)
      @user_scope = user_scope
      @editable = editable
    end

    def call
      return if user_scope.admin? # admins can see everything, no filtering required

      editable ? editable_filter : readable_filter
    end

    private

    attr_reader :user_scope, :editable

    def editable_filter
      target_query(user_scope.edit_targets) || MATCH_NONE_FILTER
    end

    def readable_filter
      # not an admin?  first include any objects the user can explicitly edit or has read_restricted access to
      queries = [target_query(user_scope.allowed_targets)]

      if user_scope.read_unrestricted?
        restricted_query = target_query(user_scope.all_restricted_targets)
        return if restricted_query.nil? # no filtering required if aren't any restricted objects for read_unrestricted

        # read_unrestricted will match all objects except those governed by object/collection/APOs marked as restricted
        queries << "(*:* AND NOT #{restricted_query})"
      end
      queries.compact!

      # Users with no matching permissions need a match-none filter, thus returning no results (should be rare),
      # but returning nil would leave the Solr query unrestricted though, so this is a guard against that.
      return MATCH_NONE_FILTER if queries.empty?

      queries.join(' OR ')
    end

    # Builds a query matching target druids from permission records (`Permission`) against
    # an object's druid, collection druids, or governing APO druid.
    # Returns nil if no targets, so the caller can distinguish no specific targeted access from a match-all query.
    def target_query(targets)
      return if targets.empty?

      values = targets.map { |target| "\"#{RSolr.solr_escape(target)}\"" }.join(' OR ')
      "(#{TARGET_FIELDS.map { |field| "#{field}:(#{values})" }.join(' OR ')})"
    end
  end
end
