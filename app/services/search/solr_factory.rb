# frozen_string_literal: true

module Search
  # Factory for Solr connections
  class SolrFactory
    # @return [RSolr::Client]
    def self.call
      RSolr.connect(url: Settings.solr.url)
    end
  end
end
