# frozen_string_literal: true

module Searchers
  # Base searcher for streaming a report
  class BaseReport
    def self.call(...)
      new(...).call
    end

    # @param fields [Array<String>] fields to include in the report
    # @param rows [Integer] number of rows to return
    # @param stream [IO, nil] stream to write results to; if nil, returns CSV::Table.
    # @return [CSV::Table, nil] search results if stream is nil, otherwise CSV::Table.
    def initialize(fields:, rows:, stream: nil)
      @fields = fields
      @rows = rows
      @stream = stream
    end

    # @return [SearchResults::Items] search results
    def call
      if stream
        Search::SolrService.stream(request: solr_request, stream:, replacement_header:)
      else
        CSV.parse(csv_string, headers: true)
      end
    end

    private

    attr_reader :rows, :fields, :stream

    # @return [Hash] solr request query specific to the report
    def solr_request_query
      raise NotImplementedError, 'Subclasses must implement solr_request_query'
    end

    def solr_request
      {
        fl: fields,
        rows:,
        wt: :csv,
        'csv.mv.separator' => ';'
      }.merge(solr_request_query)
    end

    def csv_string
      Search::SolrService.post(request: solr_request).tap do |csv|
        csv.sub!(/^.*?\n/m, replacement_header) if replacement_header
      end
    end

    def replacement_header
      CSV.generate_line(fields.map do |field|
        config = Reports::Fields.find_config_by_field(field)
        config ? config.label : field
      end)
    end
  end
end
