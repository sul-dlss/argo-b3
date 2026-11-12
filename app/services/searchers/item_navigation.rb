# frozen_string_literal: true

module Searchers
  # Searcher for the items immediately before and after an item in a search result set.
  # Used for the item page search result navigation
  class ItemNavigation
    Result = Struct.new(:previous_druid, :next_druid, :total_results)

    def self.call(...)
      new(...).call
    end

    # @param druid [String] the item at position when the search was run
    # @param search_form [SearchForm]
    # @param position [Integer] 1-based absolute position within the result set
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(druid:, search_form:, position:, user_scope:)
      @druid = druid
      @search_form = search_form
      @position = position
      @user_scope = user_scope
    end

    # @return [Result, nil] navigation details, or nil if the item is no longer at position (e.g., it was edited)
    def call
      return if druids[current_index] != druid

      Result.new(previous_druid:, next_druid:, total_results: response.fetch('numFound'))
    end

    private

    attr_reader :druid, :search_form, :user_scope, :position

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
      Search::ItemQueryBuilder.call(search_form:, user_scope:).merge(
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

    # @return [String] Solr sort value
    def sort
      Search::SortOptions.sort_value_for(search_form.sort)
    end
  end
end
