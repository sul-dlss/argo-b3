# frozen_string_literal: true

module Elements
  module Pagination
    class SectionComponent < ApplicationComponent
      ELLIPSIS = '...'

      # @param total_pages [Integer] total number of pages
      # @param current_page [Integer] current page number
      # @param path_func [Proc] a proc that takes a page number and returns the path for that page
      def initialize(total_pages:, current_page:, path_func:)
        @total_pages = total_pages
        @current_page = current_page
        @path_func = path_func
        super()
      end

      attr_reader :total_pages, :current_page, :path_func

      def render?
        total_pages > 1
      end

      def previous_active?
        current_page > 1
      end

      def next_active?
        current_page < total_pages
      end

      def previous_path
        previous_active? ? path_func.call(current_page - 1) : '#'
      end

      def previous_classes
        merge_classes('page-item', ('disabled' unless previous_active?))
      end

      def next_path
        next_active? ? path_func.call(current_page + 1) : '#'
      end

      def next_classes
        merge_classes('page-item', ('disabled' unless next_active?))
      end

      def pages
        # Always show first 2 and last 2 pages
        # Also show the 5-page range that the current page is part of.
        # For example, for 21, 22, 23, 24 or 25, this is pages 21-25.
        # Insert ellipses where there are gaps.
        range_start = (((current_page - 1) / 5) * 5) + 1
        range_end = [range_start + 4, total_pages].min
        pages = [1, 2, total_pages - 1, total_pages] + (range_start..range_end).to_a
        with_ellipses(pages.uniq.sort)
      end

      def with_ellipses(pages)
        [].tap do |pages_with_ellipses|
          pages.each_with_index do |page, index|
            pages_with_ellipses << ELLIPSIS if index.positive? && page - pages[index - 1] > 1
            pages_with_ellipses << page
          end
        end
      end
    end
  end
end
