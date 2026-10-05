# frozen_string_literal: true

# Controller for APOs
class AposController < ApplicationController
  # Values for submit buttons
  DEPOSIT_VALUE = 'deposit'
  DRAFT_VALUE = 'draft'
  DRAFT_TO_ADD_FILES_VALUE = 'add_files'

  def new
    authorize! with: ApoPolicy

    @apo_form = ApoForm.new
    @cancel_path = (request.referer if request.referer.present? && request.referer.exclude?(new_apo_path)) || root_path

    set_agreement_options
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

  private

  def apo_form_params
    params.permit(apo: ApoForm.permitted_params)[:apo]
  end

  def set_agreement_options
    @agreement_options = Searchers::AgreementList.call(user_scope: current_user_scope)
  end

  # def create_redirect_path
  #   if params[:commit] == DRAFT_TO_ADD_FILES_VALUE
  #     edit_content_path(@item_form.druid)
  #   else
  #     object_path(@item_form.druid)
  #   end
  # end
end
