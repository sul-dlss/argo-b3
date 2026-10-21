# frozen_string_literal: true

module Searchers
  # Searcher that returns the list of Admin Policy Objects (APOs), for populating select options.
  class AdminPolicyList
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @param editable [Boolean] when true, limits to the APOs the user can edit (e.g., to govern a new object),
    #   rather than those the user can read
    def initialize(user_scope:, editable: false)
      @user_scope = user_scope
      @editable = editable
    end

    # @return [Array<Array(String, String)>] list of [title, druid] pairs, sorted by title
    def call
      solr_response['response']['docs'].map { |doc| [doc[TITLE], doc[ID]] }
    end

    private

    attr_reader :user_scope, :editable

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      {
        q: '*:*',
        fq: ["#{OBJECT_TYPES}:APO", permission_filter].compact,
        fl: [ID, TITLE],
        sort: Search::SortOptions::TITLE.sort_value,
        rows: 10_000
      }
    end

    # @return [String, nil] the Solr filter query restricting the APOs to the user's permissions, nil if none
    def permission_filter
      return Search::PermissionFilter.call(user_scope:) unless editable
      return if user_scope.admin?

      editable_apo_filter
    end

    # An edit permission allows creating objects governed by the target APO itself (see Permission),
    # unlike Search::PermissionFilter, which also matches objects governed by or members of a target.
    # @return [String] the Solr filter query matching the APOs that are edit targets
    def editable_apo_filter
      targets = user_scope.edit_targets
      return Search::PermissionFilter::MATCH_NONE_FILTER if targets.empty?

      "#{ID}:(#{targets.map { |target| "\"#{RSolr.solr_escape(target)}\"" }.join(' OR ')})"
    end
  end
end
