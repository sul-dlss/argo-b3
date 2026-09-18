# frozen_string_literal: true

# Base controller for search-related actions
class SearchApplicationController < ApplicationController
  include SearchFormConcern

  before_action :set_search_form
  # Searching doesn't require authorization.
  skip_verify_authorized

  private

  def selected_facet_labels
    druids = @search_form.admin_policy_druids + @search_form.collection_druids
    Searchers::FacetLabels.call(druids:)
  end
end
