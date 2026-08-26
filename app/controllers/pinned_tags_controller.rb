# frozen_string_literal: true

# Controller for managing pinned tags
class PinnedTagsController < ApplicationController
  # Any caller of create or destroy will want to include:
  # <% content_for :head do %>
  #   <meta name="turbo-refresh-method" content="morph">
  #   <meta name="turbo-refresh-scroll" content="preserve">
  # <% end %>

  # No reason to authorize since the user can only be the user.
  skip_verify_authorized

  def create
    PinnedTag.find_or_create_by!(user: current_user, tag: params[:tag])

    flash[:toast] = t('pinned.pin_added')

    redirect_to request.referer || root_path, status: :see_other
  end

  def destroy
    pinned_tag = PinnedTag.find_by!(tag: params.expect(:id), user: current_user)
    pinned_tag.destroy!

    flash[:toast] = t('pinned.pin_removed')

    redirect_to request.referer || root_path, status: :see_other
  end
end
