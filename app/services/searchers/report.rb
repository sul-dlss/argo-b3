# frozen_string_literal: true

module Searchers
  # Searcher for streaming a report
  class Report < BaseReport
    # @param search_form [SearchForm]
    # @param workgroups [Array<String>, nil] workgroups used to determine permissions
    def initialize(search_form:, workgroups:, fields:, rows:, stream: nil)
      @search_form = search_form
      @workgroups = workgroups
      super(fields:, rows:, stream:)
    end

    private

    attr_reader :search_form, :workgroups

    def solr_request_query
      Search::ItemQueryBuilder.call(search_form:, workgroups:)
    end
  end
end
