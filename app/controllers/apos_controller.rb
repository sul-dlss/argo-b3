# frozen_string_literal: true

# Controller for APOs
class AposController < ApplicationController
  before_action :set_druid_and_cocina_object, only: %i[edit update]

  def new
    authorize! with: ApoPolicy

    @apo_form = ApoForm.new
    @cancel_path = (request.referer if request.referer.present? && request.referer.exclude?(new_apo_path)) || root_path

    set_agreement_options
  end

  def edit
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @edit_apo_form = EditApoForm.build_from_cocina_object(@cocina_object)
    @edit_apo_form.version_service = version_service
    @edit_apo_form.prefill_version_description
    set_edit_view
  end

  def create
    authorize! with: ApoPolicy

    @apo_form = ApoForm.new(apo_form_params)

    if @apo_form.valid?
      @apo_form.create!(user_name: current_user.sunetid, accession: true)
      flash[:toast] = t('edit.apos.new.toasts.register')
      redirect_to object_path(@apo_form.druid)
    else
      set_agreement_options
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?
    return redirect_stale if stale?

    @edit_apo_form = build_submitted_edit_apo_form
    return render_invalid_edit unless @edit_apo_form.valid?

    # Editing an APO always deposits it.
    @edit_apo_form.save!(user_name: current_user.sunetid, accession: true)
    redirect_to object_path(@druid), flash: { toast: t('edit.apos.edit.toasts.deposited') }
  end

  private

  def apo_form_params
    ApoForm.params_from(params)
  end

  def edit_apo_form_params
    EditApoForm.params_from(params)
  end

  def build_submitted_edit_apo_form
    EditApoForm.build_from_cocina_object(@cocina_object).tap do |form|
      form.version_service = version_service
      form.update(edit_apo_form_params)
    end
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { warning: t('edit.apos.edit.warnings.not_editable') }
  end

  # The lock changes whenever the object is updated, so a different (or missing) lock means that the object
  # was changed after the edit page was loaded.
  def stale?
    edit_apo_form_params[:lock] != @cocina_object.lock
  end

  def redirect_stale
    redirect_to edit_apo_path(@druid), flash: { warning: t('edit.apos.edit.warnings.stale') }
  end

  # The saved title is shown, so that it is not replaced by an invalid submitted title.
  def set_edit_view
    @title = Cocina::Models::Builders::TitleBuilder.build(@cocina_object.description.title)
    set_agreement_options(current_agreement_druid: @cocina_object.administrative.hasAgreement)
  end

  def render_invalid_edit
    set_edit_view
    render :edit, status: :unprocessable_content
  end

  def set_agreement_options(current_agreement_druid: nil)
    @agreement_options = agreement_options(current_agreement_druid:)
  end

  # The agreements the user can see, plus an existing APO's current agreement (even if the user cannot see it),
  # so that saving an edit does not change it. Since its title is not found, it is labeled with its druid.
  def agreement_options(current_agreement_druid:)
    options = Searchers::AgreementList.call(user_scope: current_user_scope)
    return options if current_agreement_druid.blank? || options.any? { |option| option.last == current_agreement_druid }

    [[DruidSupport.bare_druid_from(current_agreement_druid), current_agreement_druid]] + options
  end

  def set_druid_and_cocina_object
    @druid = params[:id]
    @cocina_object = Sdr::Repository.find(druid: @druid)
  end
end
