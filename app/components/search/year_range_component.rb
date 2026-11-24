# frozen_string_literal: true

module Search
  # Component for filtering the Year facet by a range of years (from and/or to)
  class YearRangeComponent < ViewComponent::Base
    # @param search_form [SearchForm] The current search form
    def initialize(search_form:)
      @search_form = search_form
      super()
    end

    attr_reader :search_form
  end
end
