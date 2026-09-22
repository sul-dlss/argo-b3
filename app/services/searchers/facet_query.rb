# frozen_string_literal: true

module Searchers
  # Searcher for performing a facet query.
  # This is a separate searcher because the JSON Facet API does not support "contains".
  # This uses the standard Solr faceting parameters.
  class FacetQuery
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param facet_config [Search::Facets::Config] configuration for the facet
    # @param facet_query [String] query to filter facet values
    # @param limit [Integer, nil] maximum number of facet values to return
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(search_form:, facet_config:, facet_query:, user_scope:, limit: nil)
      @search_form = search_form
      @user_scope = user_scope
      @facet_config = facet_config
      @limit = limit
      @facet_query = facet_query
    end

    # @return [SearchResults::FacetQueryCounts] search results
    def call
      SearchResults::FacetQueryCounts.new(solr_response:, facet_config:)
    end

    private

    attr_reader :search_form, :user_scope, :facet_config, :limit, :facet_query

    delegate :alpha_sort, to: :facet_config

    def field
      facet_config.facet_field
    end

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:, user_scope:).merge(
        {
          facet: true,
          'facet.field': [field],
          rows: 0,
          'facet.contains': facet_query,
          'facet.contains.ignoreCase': true
        }.tap do |req|
          req['facet.sort'] = 'alpha' if alpha_sort
          req['facet.limit'] = limit if limit
        end
      )
    end
  end
end
