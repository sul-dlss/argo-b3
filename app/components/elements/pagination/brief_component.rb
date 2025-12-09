# frozen_string_literal: true

module Elements
  module Pagination
    # Component for displaying a brief pagination section (that typically goes on the top of the page)
    # << Previous 41-60 of 778 Next >>
    class BriefComponent < ApplicationComponent
      # @param total_pages [Integer] total number of pages
      # @param current_page [Integer] current page number
      # @param path_func [Proc] a proc that takes a page number and returns the path for that page
      # @param total_results [Integer] total number of results
      # @param per_page [Integer] number of results per page
      def initialize(total_pages:, current_page:, path_func:, total_results:, per_page:)
        @total_pages = total_pages
        @current_page = current_page
        @path_func = path_func
        @total_results = total_results
        @per_page = per_page
        super()
      end

      attr_reader :total_pages, :current_page, :path_func, :total_results, :per_page

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

      def next_path
        next_active? ? path_func.call(current_page + 1) : '#'
      end

      def first_result
        ((current_page - 1) * per_page) + 1
      end

      def last_result
        [current_page * per_page, total_results].min
      end

      def next_classes
        merge_classes('page-link ms-2', ('disabled' unless next_active?))
      end

      def previous_classes
        merge_classes('page-link me-2', ('disabled' unless previous_active?))
      end
    end
  end
end
