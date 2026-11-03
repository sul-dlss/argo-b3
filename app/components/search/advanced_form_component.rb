# frozen_string_literal: true

module Search
  # Input for a Boolean query, keeping separately selected facets when resubmitted.
  class AdvancedFormComponent < ViewComponent::Base
    def initialize(search_form:)
      @search_form = search_form
      super()
    end

    attr_reader :search_form
  end
end
