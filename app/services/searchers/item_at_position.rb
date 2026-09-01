# frozen_string_literal: true

module Searchers
  # Searcher that returns the druid at an absolute position within a search result set.
  class ItemAtPosition
    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param position [Integer] 1-based absolute position within the result set
    def initialize(search_form:, position:)
      @search_form = search_form
      @position = position
    end

    # @return [String, nil] the druid at the given position, or nil if out of range
    def call
      solr_response['response']['docs'].pick('id')
    end

    private

    attr_reader :search_form, :position

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          fl: [Search::Fields::ID],
          rows: 1,
          start: position - 1,
          sort:
        }
      )
    end

    # @return [String, nil] Solr sort value or nil if none
    def sort
      Search::SortOptions.find_config_by_sort_field(search_form.sort)&.sort_value
    end
  end
end
