# frozen_string_literal: true

module Search
  # Component for displaying a single facet search result (for stimulus-autocomplete)
  class FacetSearchResultComponent < ViewComponent::Base
    with_collection_parameter :facet_count

    def initialize(facet_count:)
      @facet_count = facet_count
      super()
    end

    attr_reader :facet_count

    delegate :value, :count, to: :facet_count
  end
end
