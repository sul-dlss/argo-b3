# frozen_string_literal: true

module Search
  # Component for the sort pulldown on search results.
  class SortComponent < ApplicationComponent
    def initialize(search_form:)
      @search_form = search_form
      super()
    end

    attr_reader :search_form

    def dropdown_label
      "Sort by #{label_for(current_sort_option)}"
    end

    def sort_options
      %w[relevance druid]
    end

    def label_for(sort_option)
      Search::SortOptions.find_config_by_sort_field(sort_option)&.label
    end

    private

    def current_sort_option
      search_form.sort || 'relevance'
    end
  end
end
