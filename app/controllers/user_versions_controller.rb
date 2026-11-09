# frozen_string_literal: true

# Controller for withdrawing and restoring the user (public) versions of an object.
class UserVersionsController < ApplicationController
  include TokenConcern
  include VersionsTableConcern

  # The versions frame's download links are authorized by a druid signed for ObjectsController#show.
  self.token_purpose = 'show'

  before_action :set_cocina_object

  def withdraw
    authorize! @cocina_object, to: :manage_user_versions?, with: ObjectPolicy

    update_user_version(withdraw: true, toast: t('user_versions.toasts.withdrawn'))
  end

  def restore
    authorize! @cocina_object, to: :manage_user_versions?, with: ObjectPolicy

    update_user_version(withdraw: false, toast: t('user_versions.toasts.restored'))
  end

  private

  def set_cocina_object
    @cocina_object = Sdr::Repository.find(druid:, without_structural_contains: true)
  end

  def druid
    params.expect(:object_druid)
  end

  def update_user_version(withdraw:, toast:) # rubocop:disable Metrics/AbcSize
    Sdr::UserVersionService.update(druid:, user_version: params[:user_version].to_i, withdraw:)
    flash.now[:toast] = toast
    render_versions_frame
  rescue Sdr::Repository::Error => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: })
    flash.now[:danger] = t('user_versions.errors.update_failed')
    render_versions_frame(status: :unprocessable_content)
  end

  def render_versions_frame(status: :ok)
    @druid = druid
    @versions_table = versions_table_component(druid:, cocina_object: @cocina_object)
    render :versions_frame, status:
  end
end
