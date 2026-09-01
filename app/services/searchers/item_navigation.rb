# frozen_string_literal: true

module Searchers
  # Searcher for the items immediately before and after an item in a search result set.
  class ItemNavigation
    Result = Struct.new(:previous_druid, :next_druid, :total_results)

    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param position [Integer] 1-based absolute position within the result set
    # @param current_druid [String] druid expected at the given position
    def initialize(search_form:, position:, current_druid:)
      @search_form = search_form
      @position = position
      @current_druid = current_druid
    end

    # @return [Result, nil] navigation details, or nil when the search context is stale
    def call
      return unless current_item?

      Result.new(previous_druid:, next_druid:, total_results: response.fetch('numFound'))
    end

    private

    attr_reader :search_form, :position, :current_druid

    def current_item?
      druids[current_index] == current_druid
    end

    def previous_druid
      druids[current_index - 1] if current_index.positive?
    end

    def next_druid
      druids[current_index + 1]
    end

    def druids
      @druids ||= response.fetch('docs').pluck(Search::Fields::ID)
    end

    def response
      @response ||= solr_response.fetch('response')
    end

    def current_index
      position - start - 1
    end

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      Search::ItemQueryBuilder.call(search_form:).merge(
        {
          fl: [Search::Fields::ID],
          rows: 3,
          start:,
          sort:
        }
      )
    end

    def start
      [position - 2, 0].max
    end

    # @return [String, nil] Solr sort value or nil if none
    def sort
      Search::SortOptions.find_config_by_sort_field(search_form.sort)&.sort_value
    end
  end
end
