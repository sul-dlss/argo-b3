# frozen_string_literal: true

# Controller for searches
class SearchController < SearchApplicationController
  def show
    @pinned = PinnedSearch.exists_by_search_form?(search_form: @search_form, user: current_user)
  end
end
