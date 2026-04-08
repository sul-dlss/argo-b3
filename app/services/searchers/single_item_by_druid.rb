# frozen_string_literal: true

module Searchers
  # Searcher for single items (DROs, collections, or APOs) by druid.
  class SingleItemByDruid
    def self.call(...)
      new(...).call
    end

    # @param druid [String]
    # @param fields [Array<String>] fields to include in the search results; defaults to Searchers::Items::FIELD_LIST
    def initialize(druid:, fields: Searchers::Item::FIELD_LIST)
      @druid = druid
      @fields = fields
    end

    # @return [SearchResults::Item] search result
    def call
      SearchResults::Item.new(solr_doc: solr_response['response']['docs'].first, index: 1)
    end

    private

    attr_reader :druid, :fields

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      {
        fq: "#{Search::Fields::ID}:(\"#{druid}\")",
        fl: fields,
        rows: 1
      }
    end
  end
end
