# frozen_string_literal: true

# Controller for agreements
class AgreementsController < ApplicationController
  include EditCocinaObjectConcern
  include RegisterCancelConcern

  edit_form EditAgreementForm

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
    return redirect_not_editable unless version_service.draft_editable?

    @edit_agreement_form = prefilled_edit_form
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

  def update # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.draft_editable?

    @edit_agreement_form = submitted_edit_form
    return redirect_stale if @edit_agreement_form.stale?
    return redirect_assembly_stopped_with_error if deposit? && version_service.assembly_stopped_with_error?

    # The mutable Content must follow the object to its new lock.
    @edit_agreement_form.content = Content.mutable_for(@cocina_object)
    return redirect_content_busy if @edit_agreement_form.content&.busy?

    return render_invalid_edit unless @edit_agreement_form.valid?(deposit? ? :deposit : nil)

    @edit_agreement_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_updated
  end

  private

  def new_agreement_form_params
    NewAgreementForm.params_from(params)
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

  # The saved title is shown, so that it is not replaced by an invalid submitted title.
  def set_edit_view
    @title = CocinaSupport.title(@cocina_object)
    # Computed once, since every pane's footer renders the discard or purge button.
    @draft_actions_presenter = DraftActionsPresenter.new(cocina_version: @cocina_object.version, version_service:)
  end
end
