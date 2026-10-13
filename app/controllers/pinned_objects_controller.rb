# frozen_string_literal: true

# Controller for managing pinned objects
class PinnedObjectsController < ApplicationController
  include ToastAndRefreshConcern

  # No reason to authorize since the user can only be the user.
  skip_verify_authorized

  def create
    PinnedObject.find_or_create_by!(user: current_user, druid: params[:druid])

    toast_and_refresh(t('pinned.pin_added'))
  end

  def destroy
    pinned_object = PinnedObject.find_by!(druid: params.expect(:id), user: current_user)
    pinned_object.destroy!

    toast_and_refresh(t('pinned.pin_removed'))
  end
end
