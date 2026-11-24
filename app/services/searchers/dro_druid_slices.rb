# frozen_string_literal: true

module Searchers
  # Pages through the druids of every DRO (Items, Agreements, and Virtual Objects) in Solr, a slice at a time.
  # It keeps its own state rather than being an Enumerator, so #next can be called from different threads.
  class DroDruidSlices
    PAGE_SIZE = 1000

    # @param slice_size [Integer] the number of druids per slice
    def initialize(slice_size:)
      @slice_size = slice_size
      @slices = []
      @cursor_mark = '*'
    end

    # @return [Integer, nil] the number of DROs, as of the first page; nil until the first slice is requested
    attr_reader :total_count

    # @return [Array<String>, nil] the next slice of druids, or nil after the last
    def next
      fetch_page while slices.empty? && cursor_mark
      slices.shift
    end

    private

    attr_reader :slice_size, :slices, :cursor_mark

    # Solr returns the same cursor mark once there are no more results.
    def fetch_page
      response = Search::SolrService.post(request: solr_request)
      @total_count ||= response['response']['numFound']
      slices.concat(response['response']['docs'].pluck(Search::Fields::ID).each_slice(slice_size).to_a)
      next_cursor_mark = response['nextCursorMark']
      @cursor_mark = next_cursor_mark == cursor_mark ? nil : next_cursor_mark
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
