# frozen_string_literal: true

# Controller for applying the governing APO's access and rights defaults to an item or collection, then depositing
# or, for an item, saving as a draft.
class ObjectApoDefaultsController < ApplicationController
  DEPOSIT_VALUE = ItemsController::DEPOSIT_VALUE
  DRAFT_VALUE = ItemsController::DRAFT_VALUE

  before_action :set_druid_and_cocina_object

  def new
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @apo_defaults_form = form_class.for_edit(@cocina_object, version_service:)
    set_unsaved_content_changes(content: mutable_content)
  end

  def create
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @apo_defaults_form = submitted_form
    return redirect_content_busy if @apo_defaults_form.content_busy?
    return render_invalid unless @apo_defaults_form.valid?(validation_context)

    @apo_defaults_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_saved
  rescue Sdr::Repository::Error => e
    render_save_failed(error: e)
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

  # The "Apply APO defaults" button is shown only for items and collections.
  def form_class
    @cocina_object.collection? ? CollectionApoDefaultsForm : ItemApoDefaultsForm
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  # @return [Content, nil] the item's mutable Content; a collection has none
  def mutable_content
    Content.mutable_for(@cocina_object) if @cocina_object.dro?
  end

  def submitted_form
    form_params = form_class.params_from(params)
    form_class.from_submission(@cocina_object, version_service:, params: form_params).tap do |form|
      form.content = mutable_content if @cocina_object.dro?
    end
  end

  def set_druid_and_cocina_object
    @druid = params[:druid]
    @cocina_object = Sdr::Repository.find(druid: @druid)
    @title = CocinaSupport.title(@cocina_object)
  end

  # Depositing would discard unsaved changes, so it is offered only from manage files.
  def set_unsaved_content_changes(content:)
    @unsaved_content_changes = content.present? &&
                               Contents::UnsavedChanges.call(content:, cocina_object: @cocina_object)
    @manage_files_label = helpers.manage_files_label(version_service:) if @unsaved_content_changes
  end

  # The errors of the content (e.g., not valid for the content type) and of the access built from the APO defaults
  # have no field on the page.
  def render_invalid
    errors = @apo_defaults_form.errors
    errors_without_field = errors.messages_for(:content) +
                           errors.full_messages_for(:access) + errors.full_messages_for(:embargo_access)
    flash.now[:danger] = errors_without_field.to_sentence if errors_without_field.any?
    set_unsaved_content_changes(content: mutable_content)
    render :new, status: :unprocessable_content
  end

  def render_save_failed(error:)
    Rails.logger.error(error.full_message)
    Honeybadger.notify(error)
    flash.now[:danger] = t('edit.object_apo_defaults.errors.save_failed')
    set_unsaved_content_changes(content: mutable_content)
    render :new, status: :unprocessable_content
  end

  def redirect_saved
    redirect_to object_path(@druid), flash: { toast: t("edit.object_apo_defaults.toasts.#{validation_context}") }
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { warning: t('edit.object_apo_defaults.warnings.not_editable') }
  end

  def redirect_content_busy
    redirect_to object_path(@druid), flash: { warning: t('edit.items.edit.warnings.content_busy') }
  end
end
