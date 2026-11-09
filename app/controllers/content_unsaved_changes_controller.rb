# frozen_string_literal: true

# Controller for discarding the unsaved changes of a content (canceling manage files)
class ContentUnsavedChangesController < ContentsApplicationController
  # Authorization is coming from the verified content_id token.
  skip_verify_authorized only: %i[destroy]

  def destroy
    content = Content.find(verify_token(params.expect(:content_id)))
    cocina_object = Sdr::Repository.find(druid: content.druid)

    discarded = Contents::UnsavedChangesDiscarder.call(content:, cocina_object:)
    redirect_to_object(content:, flash: discarded ? { toast: t('edit.content_unsaved_changes.toasts.discarded') } : {})
  rescue Contents::UnsavedChangesDiscarder::ContentBusyError
    redirect_to_object(content:, flash: { warning: t('edit.content_unsaved_changes.warnings.busy') })
  rescue Contents::UnsavedChangesDiscarder::StagingFailedError
    redirect_to_object(content:, flash: { warning: t('edit.content_unsaved_changes.warnings.staging_failed') })
  end

  private

  def redirect_to_object(content:, flash:)
    redirect_to object_path(content.druid), status: :see_other, flash:
  end
end
