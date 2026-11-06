# frozen_string_literal: true

module Elements
  # Component for the breadcrumb above a page's heading, linking back to its parent page.
  # The search results breadcrumb (Search::ItemNavigationComponent) adds previous/next navigation beside it.
  class BreadcrumbComponent < ApplicationComponent
    # @param label [String] The name of the page linked to.
    # @param link [String] The path of the page linked to.
    def initialize(label:, link:)
      @label = label
      @link = link
      super()
    end

    attr_reader :label, :link
  end
end
