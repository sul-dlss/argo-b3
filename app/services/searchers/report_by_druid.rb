# frozen_string_literal: true

module Searchers
  # Searcher for streaming a report for a list of druids
  class ReportByDruid < BaseReport
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(druids:, fields:, rows:, user_scope:, stream: nil)
      @druids = druids
      super(fields:, rows:, user_scope:, stream:)
    end

    private

    attr_reader :druids

    def solr_request_query
      values = druids.map { |value| "\"#{value}\"" }.join(' OR ')
      {
        fq: ["#{Search::Fields::ID}:(#{values})", Search::PermissionFilter.call(user_scope:)].compact
      }
    end
  end
end
