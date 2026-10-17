# frozen_string_literal: true

# Controller for managing pinned searches
class PinnedSearchesController < ApplicationController
  include ToastAndRefreshConcern

  # No reason to authorize since the user can only be the user.
  skip_verify_authorized

  def create
    search_form = ResultsSearchForm.new(**ResultsSearchForm.params_from(params))
    unless PinnedSearch.exists_by_search_form?(search_form:, user: current_user)
      PinnedSearch.create_from_search_form(search_form:, user: current_user)
    end

    toast_and_refresh(t('pinned.pin_added'))
  end

  def destroy
    pinned_search = PinnedSearch.find_by!(user: current_user, search_form_md5: params.expect(:id))
    pinned_search.destroy!

    toast_and_refresh(t('pinned.pin_removed'))
  end
end
