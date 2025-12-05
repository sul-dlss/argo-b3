# frozen_string_literal: true

module Searchers
  # Searcher for streaming a report
  class Report < BaseReport
    # @param search_form [SearchForm]
    def initialize(search_form:, fields:, rows:, stream: nil)
      @search_form = search_form
      super(fields:, rows:, stream:)
    end

    private

    attr_reader :search_form

    def solr_request_query
      Search::ItemQueryBuilder.call(search_form:)
    end
  end
end
