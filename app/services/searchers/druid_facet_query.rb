# frozen_string_literal: true

module Searchers
  # Searches title labels for a druid-based facet, then counts matching items by druid.
  class DruidFacetQuery
    TITLE_QUERY_FIELDS = %w[full_title_unstemmed_im full_title_tenim].freeze

    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param facet_config [Search::Facets::Config]
    # @param facet_query [String] title query
    # @param limit [Integer] maximum number of facet values to return
    def initialize(search_form:, facet_config:, facet_query:, limit:)
      @search_form = search_form
      @facet_config = facet_config
      @facet_query = facet_query
      @limit = limit
    end

    # @return [SearchResults::FacetCounts]
    def call
      labels = matching_labels
      return empty_facet_counts if labels.empty?

      response = Search::SolrService.post(request: facet_counts_request(druids: labels.keys))
      SearchResults::FacetCounts.new(solr_response: response, facet_config:, labels:)
    end

    private

    attr_reader :search_form, :facet_config, :facet_query, :limit

    delegate :field, :alpha_sort, :label_object_type, to: :facet_config

    def matching_labels
      response = Search::SolrService.post(request: label_search_request)
      response.fetch('response').fetch('docs').to_h do |doc|
        [doc.fetch(Search::Fields::ID), doc.fetch(Search::Fields::TITLE)]
      end
    end

    def label_search_request
      {
        q: facet_query,
        fq: "#{Search::Fields::OBJECT_TYPES}:#{label_object_type}",
        qf: TITLE_QUERY_FIELDS.join(' '),
        defType: 'dismax',
        fl: [Search::Fields::ID, Search::Fields::TITLE],
        rows: limit
      }
    end

    def facet_counts_request(druids:)
      request = Search::ItemQueryBuilder.call(search_form:)
      request.merge(
        fq: [*request[:fq], druid_filter(druids:)].compact,
        rows: 0,
        'json.facet': facet_json
      )
    end

    def druid_filter(druids:)
      values = druids.map { |druid| %("#{RSolr.solr_escape(druid)}") }.join(' OR ')
      "#{field}:(#{values})"
    end

    def facet_json
      {
        field => Search::FacetBuilder.call(field:, alpha_sort:, limit:)
      }.to_json
    end

    def empty_facet_counts
      SearchResults::FacetCounts.new(
        solr_response: {
          'responseHeader' => { 'params' => { 'json.facet' => facet_json } },
          'facets' => {}
        },
        facet_config:
      )
    end
  end
end
