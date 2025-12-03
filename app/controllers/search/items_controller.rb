# frozen_string_literal: true

module Search
  # Controller for item searches
  class ItemsController < SearchApplicationController
    layout false

    def index
      @results = Searchers::Item.call(search_form: @search_form)
    end

    # Retrieve some facets in a separate request to allow the main search to load faster.
    def secondary_facets
      @results = Searchers::SecondaryFacet.call(search_form: @search_form)
    end
  end
end
