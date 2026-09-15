# frozen_string_literal: true

module Search
  # Restricts the Solr results using the same target rules as ObjectPolicy so that search results
  # match the current user's view/edit permissions.
  class PermissionFilter
    TARGET_FIELDS = [Fields::ID, Fields::COLLECTION_DRUIDS, Fields::APO_DRUID].freeze
    MATCH_NONE_FILTER = '(*:* AND NOT *:*)'

    def self.call
      new.call
    end

    def initialize
      @scope = Permissions::UserScope.new(groups: Array(Current.effective_groups))
    end

    def call
      return if @scope.admin? # admins can see everything, no filtering required

      # not an admin?  first include any objects the user can explicitly edit or has read_restricted access to
      queries = [target_query(@scope.allowed_targets)]

      if @scope.read_unrestricted?
        restricted_query = target_query(@scope.all_restricted_targets)
        # read_unrestricted will match all objects except those governed by object/collection/APOs marked as restricted
        queries << (restricted_query ? "(*:* AND NOT #{restricted_query})" : '*:*')
      end
      queries.compact!

      # Users with no matching permissions need a match-none filter, thus returning no results (should be rare),
      # but returning nil would leave the Solr query unrestricted though, so this is a guard against that.
      return MATCH_NONE_FILTER if queries.empty?

      queries.join(' OR ')
    end

    private

    def target_query(targets)
      return if targets.empty?

      values = targets.map { |target| "\"#{RSolr.solr_escape(target)}\"" }.join(' OR ')
      "(#{TARGET_FIELDS.map { |field| "#{field}:(#{values})" }.join(' OR ')})"
    end
  end
end
