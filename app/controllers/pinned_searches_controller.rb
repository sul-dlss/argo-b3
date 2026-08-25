# frozen_string_literal: true

# Controller for managing pinned searches
class PinnedSearchesController < ApplicationController
  # Any caller of create or destroy will want to include:
  # <% content_for :head do %>
  #   <meta name="turbo-refresh-method" content="morph">
  #   <meta name="turbo-refresh-scroll" content="preserve">
  # <% end %>

  # No reason to authorize since the user can only be the user.
  skip_verify_authorized

  def create
    search_form = SearchForm.new(**params.permit(SearchForm.permitted_params))
    unless PinnedSearch.exists_by_search_form?(search_form:, user: current_user)
      PinnedSearch.create_from_search_form(search_form:, user: current_user)
    end

    flash[:toast] = t('pinned.pin_added')

    redirect_to request.referer || root_path, status: :see_other
  end

  def destroy
    pinned_search = PinnedSearch.find_by!(user: current_user, search_form_md5: params.expect(:id))
    pinned_search.destroy!

    flash[:toast] = t('pinned.pin_removed')

    redirect_to request.referer || root_path, status: :see_other
  end
end
