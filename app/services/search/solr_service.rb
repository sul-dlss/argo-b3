# frozen_string_literal: true

module Search
  # Service for querying Solr via POST requests
  class SolrService
    def self.call(request:)
      solr = Search::SolrFactory.call
      solr.post('select', data: request)
    end
  end
end
