# frozen_string_literal: true

module Search
  # Component for displaying a search input for a specific facet
  class FacetSearchComponent < ViewComponent::Base
    # @param facet_search_path_helper [Proc, nil] The path helper for performing the facet search
    # @param form_field [Symbol] The form field this search is for
    # @param search_form [Search::ItemForm] The current search form
    def initialize(facet_search_path_helper:, form_field:, search_form:)
      @facet_search_path_helper = facet_search_path_helper
      @form_field = form_field
      @search_form = search_form
      super()
    end

    attr_reader :form_field, :search_form, :facet_search_path_helper

    def render?
      facet_search_path_helper.present?
    end

    def data
      { controller: 'autocomplete facet-search', autocomplete_url_value: path }
    end

    def label
      "Search these #{helpers.facet_label(form_field).downcase}: "
    end

    def id
      "#{form_field}-facet-search"
    end

    def path
      facet_search_path_helper.call(search_form.with_attributes(page: nil))
    end
  end
end
