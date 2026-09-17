# frozen_string_literal: true

module Searchers
  # Searcher for counting objects matching a Solr query.
  class ObjectCount
    def self.call(...)
      new(...).call
    end

    # @param query [String] Solr query to count
    # @return [Integer] number of matching objects
    def initialize(query:)
      @query = query
    end

    def call
      solr_response.fetch('response').fetch('numFound')
    end

    private

    attr_reader :query

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      {
        q: query,
        fq: [Search::PermissionFilter.call].compact,
        rows: 0
      }
    end
  end
end
