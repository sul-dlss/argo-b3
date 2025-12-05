# frozen_string_literal: true

module Search
  # Controller for item searches
  class ItemsController < SearchApplicationController
    layout false

    def index
      @results = Searchers::Item.call(search_form: @search_form)
      set_last_search_cookie
    end

    # Retrieve some facets in a separate request to allow the main search to load faster.
    def secondary_facets
      @results = Searchers::SecondaryFacet.call(search_form: @search_form)
    end

    private

    def set_last_search_cookie
      if @search_form.blank?
        cookies.delete(:last_search)
      else
        cookies.signed[:last_search] =
          { value: { form: @search_form.without_attributes(page: nil), total_results: @results.total_results } }
      end
    end
  end
end
