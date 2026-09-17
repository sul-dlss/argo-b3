# frozen_string_literal: true

module Searchers
  # Searcher that returns a list of druids.
  class DruidList
    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(search_form:, user_scope:, limit: 10_000_000)
      @search_form = search_form
      @user_scope = user_scope
      @limit = limit
    end

    # @return [Array<String>] list of druids
    def call
      solr_response['response']['docs'].pluck('id')
    end

    private

    attr_reader :search_form, :user_scope, :limit

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:, user_scope:).merge(
        {
          fl: [Search::Fields::ID],
          rows: limit
        }
      )
    end
  end
end
