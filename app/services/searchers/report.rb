# frozen_string_literal: true

module Searchers
  # Searcher for streaming a report
  class Report < BaseReport
    # @param search_form [SearchForm]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(search_form:, fields:, rows:, user_scope:, stream: nil)
      @search_form = search_form
      super(fields:, rows:, user_scope:, stream:)
    end

    private

    attr_reader :search_form

    def solr_request_query
      Search::ItemQueryBuilder.call(search_form:, user_scope:)
    end
  end
end
