# frozen_string_literal: true

module Searchers
  # Searcher for streaming a report for a list of druids
  class ReportByDruid < BaseReport
    def initialize(druids:, fields:, rows:, stream: nil)
      @druids = druids
      super(fields:, rows:, stream:)
    end

    private

    attr_reader :druids

    def solr_request_query
      values = druids.map { |value| "\"#{value}\"" }.join(' OR ')
      {
        fq: "#{Search::Fields::ID}:(#{values})"
      }
    end
  end
end
