# frozen_string_literal: true

# Base controller for search-related actions
class SearchApplicationController < ApplicationController
  include SearchFormConcern

  before_action :set_search_form
  # Searching doesn't require authorization.
  skip_verify_authorized
end
