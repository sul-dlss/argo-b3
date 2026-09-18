# frozen_string_literal: true

module Searchers
  # Resolves druid facet values to the titles of their corresponding objects.
  class FacetLabels
    def self.call(...)
      new(...).call
    end

    # @param docs [Array<Hash>] Solr documents with id and title fields
    # @return [Hash<String, String>] labels keyed by druid
    def self.labels_from_docs(docs)
      docs.to_h { |doc| [doc.fetch(Search::Fields::ID), doc.fetch(Search::Fields::TITLE)] }
    end

    # @param druids [Array<String>]
    # @return [Hash<String, String>] labels keyed by druid
    def initialize(druids:)
      @druids = druids.compact_blank.uniq
    end

    def call
      return {} if druids.empty?

      self.class.labels_from_docs(solr_response.fetch('response').fetch('docs'))
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
      "#{Search::Fields::ID}:(#{Search::SolrFilter.quoted_values(druids)})"
    end
  end
end
