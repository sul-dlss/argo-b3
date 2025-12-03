# frozen_string_literal: true

module Search
  # Component for displaying the search form
  class FormComponent < ViewComponent::Base
    def initialize(search_form:, url:)
      @search_form = search_form
      @url = url
      super()
    end

    attr_reader :search_form, :url

    def label
      return 'Search for items:' if search_form.facets_selected?

      'Search for items, tags, projects or tickets:'
    end
  end
end
