# frozen_string_literal: true

# Controller for extracting text (OCR or speech to text) from an item
class ItemTextExtractionsController < ApplicationController
  DEPOSIT_VALUE = ItemsController::DEPOSIT_VALUE
  DRAFT_VALUE = ItemsController::DRAFT_VALUE

  before_action :set_druid_and_cocina_object

  def new
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @item_text_extraction_form = ItemTextExtractionForm.for_edit(@cocina_object, version_service:)
    set_unsaved_content_changes(content: Content.mutable_for(@cocina_object))
  end

  def create
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @item_text_extraction_form = submitted_form
    return redirect_content_busy if @item_text_extraction_form.content_busy?
    return render_invalid unless @item_text_extraction_form.valid?(validation_context)

    @item_text_extraction_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_saved
  rescue Sdr::Repository::Error => e
    render_save_failed(error: e)
  end

  private

  def deposit?
    params[:commit] == DEPOSIT_VALUE
  end

  # Depositing additionally validates the content (see ContentDepositFormConcern).
  def validation_context
    deposit? ? :deposit : :draft
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  def submitted_form
    form_params = ItemTextExtractionForm.params_from(params)
    ItemTextExtractionForm.from_submission(@cocina_object, version_service:, params: form_params)
                          .tap { |form| form.content = Content.mutable_for(@cocina_object) }
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
  end

  # The errors of the content (e.g., not valid for the content type) have no field on the page.
  def render_invalid
    content_errors = @item_text_extraction_form.errors.messages_for(:content)
    flash.now[:danger] = content_errors.to_sentence if content_errors.any?
    set_unsaved_content_changes(content: @item_text_extraction_form.content)
    render :new, status: :unprocessable_content
  end

  def render_save_failed(error:)
    Rails.logger.error(error.full_message)
    Honeybadger.notify(error)
    flash.now[:danger] = t('edit.item_text_extractions.errors.save_failed')
    set_unsaved_content_changes(content: Content.mutable_for(@cocina_object))
    render :new, status: :unprocessable_content
  end

  def redirect_saved
    redirect_to object_path(@druid), flash: { toast: t("edit.item_text_extractions.toasts.#{validation_context}") }
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { warning: t('edit.items.edit.warnings.not_editable') }
  end

  def redirect_content_busy
    redirect_to object_path(@druid), flash: { warning: t('edit.items.edit.warnings.content_busy') }
  end
end
