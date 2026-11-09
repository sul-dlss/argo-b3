# frozen_string_literal: true

# Controller for agreements
class AgreementsController < ApplicationController
  include RegisterCancelConcern

  before_action :set_druid_and_cocina_object, only: %i[edit update]

  # Values for submit buttons
  DRAFT_VALUE = 'draft'
  DRAFT_TO_ADD_FILES_VALUE = 'add_files'
  DEPOSIT_VALUE = 'deposit'

  def new
    authorize! with: AgreementPolicy

    @new_agreement_form = NewAgreementForm.new
    @cancel_path = register_cancel_path
  end

  def edit
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @edit_agreement_form = EditAgreementForm.build_from_cocina_object(@cocina_object)
    @edit_agreement_form.version_service = version_service
    @edit_agreement_form.prefill_version_description
    set_edit_view
  end

  def create
    authorize! with: AgreementPolicy

    @new_agreement_form = NewAgreementForm.new(new_agreement_form_params)

    if @new_agreement_form.valid?
      @new_agreement_form.create!(user_name: current_user.sunetid)
      flash[:toast] = t('edit.agreements.new.toasts.register')
      redirect_to create_redirect_path
    else
      @cancel_path = root_path
      render :new, status: :unprocessable_content
    end
  end

  def update # rubocop:disable Metrics/AbcSize
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?
    return redirect_stale if stale?

    # The mutable Content must follow the object to its new lock.
    @content = Content.mutable_for(@cocina_object)
    return redirect_content_busy if @content&.staging_or_discovering?

    @edit_agreement_form = build_submitted_edit_agreement_form
    return render_invalid_edit unless @edit_agreement_form.valid?(deposit? ? :deposit : nil)

    @edit_agreement_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_updated
  end

  private

  def new_agreement_form_params
    NewAgreementForm.params_from(params)
  end

  def edit_agreement_form_params
    EditAgreementForm.params_from(params)
  end

  def build_submitted_edit_agreement_form
    EditAgreementForm.build_from_cocina_object(@cocina_object).tap do |form|
      form.version_service = version_service
      form.update(edit_agreement_form_params)
      form.content = @content
    end
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  def deposit?
    params[:commit] == DEPOSIT_VALUE
  end

  def add_files?
    params[:commit] == DRAFT_TO_ADD_FILES_VALUE
  end

  def create_redirect_path
    add_files? ? edit_content_path(@new_agreement_form.druid) : object_path(@new_agreement_form.druid)
  end

  def redirect_updated
    toast_key = deposit? ? 'deposited' : 'updated'
    redirect_to add_files? ? edit_content_path(@druid) : object_path(@druid),
                flash: { toast: t("edit.agreements.edit.toasts.#{toast_key}") }
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { warning: t('edit.agreements.edit.warnings.not_editable') }
  end

  # The lock changes whenever the object is updated, so a different (or missing) lock means that the object
  # was changed after the edit page was loaded.
  def stale?
    edit_agreement_form_params[:lock] != @cocina_object.lock
  end

  def redirect_stale
    redirect_to edit_agreement_path(@druid), flash: { warning: t('edit.agreements.edit.warnings.stale') }
  end

  def redirect_content_busy
    redirect_to edit_agreement_path(@druid), flash: { warning: t('edit.agreements.edit.warnings.content_busy') }
  end

  # The saved title is shown, so that it is not replaced by an invalid submitted title.
  def set_edit_view
    @title = CocinaSupport.title(@cocina_object)
    # Computed once, since every pane's footer renders the discard or purge button.
    @discard_or_purge_presenter = DiscardOrPurgePresenter.new(cocina_version: @cocina_object.version, version_service:)
  end

  def render_invalid_edit
    set_edit_view
    render :edit, status: :unprocessable_content
  end

  def set_druid_and_cocina_object
    @druid = params[:id]
    @cocina_object = Sdr::Repository.find(druid: @druid)
  end
end
