# frozen_string_literal: true

# Controller for searches
class SearchController < SearchApplicationController
  def show
    @search_form = build_form(form_class: SearchForm)
  end
end
