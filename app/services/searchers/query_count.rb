# frozen_string_literal: true

module Searchers
  # Searcher for counting solr docs matching a Solr query.
  class QueryCount
    def self.call(...)
      new(...).call
    end

    # @param query [String] Solr query to count
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @return [Integer] number of matching results
    def initialize(query:, user_scope:)
      @query = query
      @user_scope = user_scope
    end

    def call
      solr_response.fetch('response').fetch('numFound')
    end

    private

    attr_reader :query, :user_scope

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      {
        q: query,
        fq: [Search::PermissionFilter.call(user_scope:)].compact,
        rows: 0
      }
    end
  end
end
