# frozen_string_literal: true

module Searchers
  # Resolves druid facet values to the titles of their corresponding objects.
  class FacetLabels
    def self.call(...)
      new(...).call
    end

    # @param druids [Array<String>]
    # @return [Hash<String, String>] labels keyed by druid
    def initialize(druids:)
      @druids = druids.compact_blank.uniq
    end

    def call
      return {} if druids.empty?

      solr_response.fetch('response').fetch('docs').to_h do |doc|
        [doc.fetch(Search::Fields::ID), doc.fetch(Search::Fields::TITLE)]
      end
    end

    private

    attr_reader :druids

    def solr_response
      Search::SolrService.post(request: {
                                 q: '*:*',
                                 fq: druid_filter,
                                 fl: [Search::Fields::ID, Search::Fields::TITLE],
                                 rows: druids.size
                               })
    end

    def druid_filter
      values = druids.map { |druid| %("#{RSolr.solr_escape(druid)}") }.join(' OR ')
      "#{Search::Fields::ID}:(#{values})"
    end
  end
end
