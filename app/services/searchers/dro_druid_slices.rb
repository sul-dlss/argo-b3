# frozen_string_literal: true

module Searchers
  # Pages through the druids of every DRO (Items, Agreements, and Virtual Objects) in Solr, a slice at a time.
  # It keeps its own state rather than being an Enumerator, so #next can be called from different threads.
  class DroDruidSlices
    PAGE_SIZE = 1000

    # @param slice_size [Integer] the number of druids per slice
    # @param limit [Integer, nil] the most druids to return, the first in druid order; nil for all.
    #   Druids are minted at random, so the first druids are a sample of all of them.
    def initialize(slice_size:, limit: nil)
      @slice_size = slice_size
      @limit = limit
      @slices = []
      @cursor_mark = '*'
      @fetched_count = 0
    end

    # @return [Integer, nil] the number of druids that will be returned, as of the first page;
    #   nil until the first slice is requested
    def total_count
      @total_count && limit ? [@total_count, limit].min : @total_count
    end

    # @return [Array<String>, nil] the next slice of druids, or nil after the last
    def next
      fetch_page while slices.empty? && cursor_mark
      slices.shift
    end

    private

    attr_reader :slice_size, :limit, :slices, :cursor_mark

    def fetch_page
      response = Search::SolrService.post(request: solr_request)
      @total_count ||= response['response']['numFound']
      druids = within_limit(response['response']['docs'].pluck(Search::Fields::ID))
      @fetched_count += druids.size
      slices.concat(druids.each_slice(slice_size).to_a)
      @cursor_mark = next_cursor_mark(response:)
    end

    def within_limit(druids)
      limit ? druids.first(limit - @fetched_count) : druids
    end

    # Solr returns the same cursor mark once there are no more results.
    def next_cursor_mark(response:)
      return if limit && @fetched_count >= limit

      response['nextCursorMark'] == cursor_mark ? nil : response['nextCursorMark']
    end

    def solr_request
      {
        q: '*:*',
        fq: ["#{Search::Fields::OBJECT_TYPES}:(item OR agreement OR \"virtual object\")"],
        fl: [Search::Fields::ID],
        sort: "#{Search::Fields::ID} asc",
        rows: PAGE_SIZE,
        cursorMark: cursor_mark
      }
    end
  end
end
