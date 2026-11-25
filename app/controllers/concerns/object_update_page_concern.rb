# frozen_string_literal: true

# Concern for a page from the object page's Update list that changes an item or collection, then deposits or, for an
# item, saves as a draft. Includers define form_class and errors_without_field; messages are under
# edit.<controller name>.
module ObjectUpdatePageConcern
  extend ActiveSupport::Concern

  DEPOSIT_VALUE = ItemsController::DEPOSIT_VALUE
  DRAFT_VALUE = ItemsController::DRAFT_VALUE

  included do
    before_action :set_druid_and_cocina_object
  end

  private

  # A collection is always deposited, since it cannot be saved as a draft.
  def deposit?
    @cocina_object.collection? || params[:commit] == DEPOSIT_VALUE
  end

  # Depositing an item additionally validates its content (see ContentDepositFormConcern).
  def validation_context
    deposit? ? :deposit : :draft
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  # @return [Content, nil] the item's mutable Content; a collection has none
  def mutable_content
    Content.mutable_for(@cocina_object) if @cocina_object.dro?
  end

  # A collection's form has no content.
  def submitted_form
    form = form_class.from_submission(@cocina_object, version_service:, params: form_class.params_from(params))
    content = mutable_content
    form.content = content if content
    form
  end

  def set_druid_and_cocina_object
    @druid = params[:druid]
    @cocina_object = Sdr::Repository.find(druid: @druid)
    @title = CocinaSupport.title(@cocina_object)
  end

  # Depositing would discard unsaved changes, so it is offered only from manage files.
  def set_unsaved_content_changes
    content = mutable_content
    @unsaved_content_changes = content.present? &&
                               Contents::UnsavedChanges.call(content:, cocina_object: @cocina_object)
    @manage_files_label = helpers.manage_files_label(version_service:) if @unsaved_content_changes
  end

  def render_invalid
    messages = errors_without_field
    flash.now[:danger] = messages.to_sentence if messages.any?
    set_unsaved_content_changes
    render :new, status: :unprocessable_content
  end

  def render_save_failed(error)
    Rails.logger.error(error.full_message)
    Honeybadger.notify(error)
    flash.now[:danger] = t("edit.#{controller_name}.errors.save_failed")
    set_unsaved_content_changes
    render :new, status: :unprocessable_content
  end

  def redirect_saved
    redirect_to object_path(@druid), flash: { toast: t("edit.#{controller_name}.toasts.#{validation_context}") }
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { warning: t("edit.#{controller_name}.warnings.not_editable") }
  end

  def redirect_content_busy
    redirect_to object_path(@druid), flash: { warning: t('edit.items.edit.warnings.content_busy') }
  end
end
