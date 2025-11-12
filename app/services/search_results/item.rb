# frozen_string_literal: true

module SearchResults
  # Search results for an item (DROs, collections, or APOs)
  class Item
    include Search::Fields

    def initialize(solr_doc:)
      @solr_doc = solr_doc
    end

    def title
      solr_doc[TITLE]
    end

    def druid
      solr_doc[ID]
    end

    def bare_druid
      solr_doc[BARE_DRUID]
    end

    attr_reader :solr_doc
  end
end
