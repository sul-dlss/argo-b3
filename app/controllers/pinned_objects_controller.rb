# frozen_string_literal: true

# Controller for managing pinned objects
class PinnedObjectsController < ApplicationController
  # Any caller of create or destroy will want to include:
  # <% content_for :head do %>
  #   <meta name="turbo-refresh-method" content="morph">
  #   <meta name="turbo-refresh-scroll" content="preserve">
  # <% end %>

  # No reason to authorize since the user can only be the user.
  skip_verify_authorized

  def create
    PinnedObject.find_or_create_by!(user: current_user, druid: params[:druid])

    flash[:toast] = 'Pin added'

    redirect_to request.referer || root_path, status: :see_other
  end

  def destroy
    pinned_object = PinnedObject.find_by!(druid: params.expect(:id), user: current_user)
    pinned_object.destroy!

    flash[:toast] = 'Pin removed'

    redirect_to request.referer || root_path, status: :see_other
  end
end
