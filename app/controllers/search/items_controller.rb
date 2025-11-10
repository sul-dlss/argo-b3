# frozen_string_literal: true

module Search
  # Controller for item searches
  class ItemsController < SearchApplicationController
    def index
      @search_form = build_form(form_class: Search::ItemForm)
      @results = Searchers::Item.call(search_form: @search_form)
    end
  end
end
