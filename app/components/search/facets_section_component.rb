# frozen_string_literal: true

module Search
  # Component for displaying a section of search facets
  class FacetsSectionComponent < ViewComponent::Base
    def initialize(search_form:)
      @search_form = search_form
      super()
    end

    attr_reader :search_form

    def blank_search?
      search_form.blank?
    end
  end
end
