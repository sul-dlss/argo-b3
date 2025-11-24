# frozen_string_literal: true

module Elements
  module Pagination
    class PageItemComponent < ApplicationComponent
      def initialize(page:, path:, current_page: false)
        @page = page
        @current_page = current_page
        @path = path
        super()
      end

      attr_reader :page, :path

      def current_page?
        @current_page
      end

      def aria_current
        current_page? ? 'page' : nil
      end

      def aria_label
        current_page? ? "Current page, Page #{page}" : "Go to page #{page}"
      end

      def classes
        merge_classes('page-item', ('active' if current_page?))
      end
    end
  end
end
