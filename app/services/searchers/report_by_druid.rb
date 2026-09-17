# frozen_string_literal: true

module Searchers
  # Searcher for streaming a report for a list of druids
  class ReportByDruid < BaseReport
    # @param workgroups [Array<String>, nil] workgroups used to determine permissions
    def initialize(druids:, workgroups:, fields:, rows:, stream: nil)
      @druids = druids
      @workgroups = workgroups
      super(fields:, rows:, stream:)
    end

    private

    attr_reader :druids, :workgroups

    def solr_request_query
      values = druids.map { |value| "\"#{value}\"" }.join(' OR ')
      {
        fq: ["#{Search::Fields::ID}:(#{values})", Search::PermissionFilter.call(workgroups:)].compact
      }
    end
  end
end
