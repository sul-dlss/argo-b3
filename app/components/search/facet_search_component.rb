# frozen_string_literal: true

module Search
  # Component for displaying a search input for a specific facet
  class FacetSearchComponent < ViewComponent::Base
    # @param path [String] Path to fetch autocomplete results
    # @param form_field [Symbol] The form field this search is for
    # @param search_form [Search::ItemForm, nil] The current search form
    def initialize(path:, form_field:, search_form:)
      @path = path
      @form_field = form_field
      @search_form = search_form
      super()
    end

    attr_reader :path, :form_field, :search_form

    def data
      { controller: 'autocomplete facet-search', autocomplete_url_value: path }
    end

    def label
      "Search these #{helpers.facet_label(form_field).downcase}: "
    end

    def id
      "#{form_field}-facet-search"
    end
  end
end
