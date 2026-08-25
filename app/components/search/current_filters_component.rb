# frozen_string_literal: true

module Search
  # Component to display the current filters applied to a search
  class CurrentFiltersComponent < ViewComponent::Base
    def initialize(search_form:, pinned:)
      @search_form = search_form
      @pinned = pinned
      super()
    end

    attr_reader :search_form, :pinned

    delegate :current_filters, to: :search_form

    def render?
      current_filters.any?
    end
  end
end
