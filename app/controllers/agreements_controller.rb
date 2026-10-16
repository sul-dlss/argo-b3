# frozen_string_literal: true

# Controller for agreements
class AgreementsController < ApplicationController
  # Values for submit buttons
  DRAFT_VALUE = 'draft'
  DRAFT_TO_ADD_FILES_VALUE = 'add_files'

  def new
    authorize! with: AgreementPolicy

    @new_agreement_form = NewAgreementForm.new
    @cancel_path = (request.referer if request.referer.present? && request.referer.exclude?(new_agreement_path)) ||
                   root_path
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

  private

  def new_agreement_form_params
    NewAgreementForm.params_from(params)
  end

  def create_redirect_path
    if params[:commit] == DRAFT_TO_ADD_FILES_VALUE
      edit_content_path(@new_agreement_form.druid)
    else
      object_path(@new_agreement_form.druid)
    end
  end
end
