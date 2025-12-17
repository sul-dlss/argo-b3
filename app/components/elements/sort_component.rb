# frozen_string_literal: true

module Elements
  # Component for the sort pulldown on search results.
  class SortComponent < ApplicationComponent
    def initialize(search_form:)
      @search_form = search_form
    end

    attr_reader :search_form

    def druid_sort_path
      search_items_path(search_form.with_attributes(sort: 'id asc', page: search_form.page))
    end

    def relevance_sort_path
      search_items_path(search_form.with_attributes(sort: 'score desc', page: search_form.page))
    end
  end
end
