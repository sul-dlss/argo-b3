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
      t('dashboard.pinned_searches.label')
    end

    def search_link(search)
      search_form = search.to_search_form
      helpers.link_to(search_form.to_s, url_for(search_form))
    end

    # Collapse the section when nothing is pinned, so empty sections don't dominate the dashboard.
    def expanded?
      pinned_searches.present?
    end

    def classes
      merge_classes('object-type-search', @classes)
    end
  end
end
