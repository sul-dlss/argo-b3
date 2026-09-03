# frozen_string_literal: true

module Searchers
  # Searcher for the items immediately before and after an item in a search result set.
  # Used for the item page search result navigation
  class ItemNavigation
    Result = Struct.new(:previous_druid, :next_druid, :total_results)

    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param position [Integer] 1-based absolute position within the result set
    def initialize(search_form:, position:)
      @search_form = search_form
      @position = position
    end

    # @return [Result] navigation details
    def call
      Result.new(previous_druid:, next_druid:, total_results: response.fetch('numFound'))
    end

    private

    attr_reader :search_form, :position

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
