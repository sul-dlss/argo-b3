# frozen_string_literal: true

module Search
  # Controller for tag searches
  class TagsController < SearchApplicationController
    def index
      @search_form = build_form(form_class: Search::Form)
      @tags = Searchers::Tag.call(search_form: @search_form, field: Search::Fields::OTHER_TAGS)
    end
  end
end
