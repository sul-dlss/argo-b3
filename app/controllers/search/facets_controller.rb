# frozen_string_literal: true

module Search
  # Controller for lazy facets
  class FacetsController < SearchApplicationController
    include Search::Fields

    def project_tags
      @search_form = build_form(form_class: Search::ItemForm)
      @facet_counts = Searchers::Facet.call(search_form: @search_form, field: PROJECT_TAGS, alpha_sort: true, limit: 25)
    end
  end
end
