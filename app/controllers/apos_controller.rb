# frozen_string_literal: true

# Controller for APOs
class AposController < ApplicationController
  include EditCocinaObjectConcern
  include RegisterCancelConcern

  edit_form EditApoForm

  def new
    authorize! with: ApoPolicy

    @apo_form = ApoForm.new
    @cancel_path = register_cancel_path

    set_agreement_options
  end

  def edit
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @edit_apo_form = prefilled_edit_form
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

    @edit_apo_form = submitted_edit_form
    return redirect_stale if @edit_apo_form.stale?
    return render_invalid_edit unless @edit_apo_form.valid?

    # Editing an APO always deposits it.
    @edit_apo_form.save!(user_name: current_user.sunetid, accession: true)
    redirect_to object_path(@druid), flash: { toast: t('edit.apos.edit.toasts.deposited') }
  end

  private

  def apo_form_params
    ApoForm.params_from(params)
  end

  # The saved title is shown, so that it is not replaced by an invalid submitted title.
  def set_edit_view
    @title = Cocina::Models::Builders::TitleBuilder.build(@cocina_object.description.title)
    set_agreement_options(current_agreement_druid: @cocina_object.administrative.hasAgreement)
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
end
