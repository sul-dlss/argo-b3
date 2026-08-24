# frozen_string_literal: true

module Dashboard
  # Render the table of a user's pinned searches on the dashboard.
  class PinnedSearchesTableComponent < ApplicationComponent
    # @param pinned_searches [Array] the pinned searches
    def initialize(pinned_searches:, classes: [])
      @pinned_searches = pinned_searches
      @classes = classes
      super()
    end

    attr_reader :pinned_searches

    def label
      'Pinned searches'
    end

    def search_link(search)
      search_form = search.to_search_form
      helpers.link_to(search_form.to_s, search_path(search_form.attributes))
    end

    def classes
      merge_classes('object-type-search', @classes)
    end
  end
end
