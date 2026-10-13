# frozen_string_literal: true

# Controller for managing pinned tags
class PinnedTagsController < ApplicationController
  include ToastAndRefreshConcern

  # No reason to authorize since tags lookup is scoped to the current user
  skip_verify_authorized

  def create
    PinnedTag.find_or_create_by!(user: current_user, tag: params[:tag])

    toast_and_refresh(t('pinned.pin_added'))
  end

  def destroy
    pinned_tag = PinnedTag.find_by!(tag: params.expect(:id), user: current_user)
    pinned_tag.destroy!

    toast_and_refresh(t('pinned.pin_removed'))
  end
end
