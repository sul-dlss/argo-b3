# frozen_string_literal: true

# Controller for items (DRO)
class ItemsController < ApplicationController
  # Values for submit buttons
  DEPOSIT_VALUE = 'deposit'
  DRAFT_VALUE = 'draft'
  DRAFT_TO_ADD_FILES_VALUE = 'add_files'

  def new
    authorize! with: ItemPolicy

    @item_form = ItemForm.new
    set_apo_options
  end

  def create
    authorize! with: ItemPolicy

    @item_form = ItemForm.new(item_form_params)

    if @item_form.valid?
      @item_form.create!(user_name: current_user.sunetid)
      flash[:toast] = t('edit.items.new.toasts.register')
      redirect_to create_redirect_path
    else
      set_apo_options
      render :new, status: :unprocessable_content
    end
  end

  def update
    druid = params[:id]
    cocina_object = Sdr::Repository.find(druid:)
    authorize! cocina_object, with: ItemPolicy

    content = find_content(cocina_object:)
    content.staging_started!
    StageFilesJob.perform_later(content:, accession: params[:commit] == DEPOSIT_VALUE, user: current_user)
    flash[:toast] = t('edit.items.new.toasts.staging_started')
    redirect_to object_path(druid)
  end

  private

  def item_form_params
    params.permit(item: ItemForm.permitted_params)[:item]
          # Hardcoding for now since required
          .merge(access_view: 'world', access_download: 'world', content_type: Cocina::Models::ObjectType.object)
  end

  def set_apo_options
    @apo_options = Searchers::AdminPolicyList.call
  end

  def create_redirect_path
    if params[:commit] == DRAFT_TO_ADD_FILES_VALUE
      edit_content_path(@item_form.druid)
    else
      object_path(@item_form.druid)
    end
  end

  def find_content(cocina_object:)
    Content.find_by(druid: cocina_object.externalIdentifier,
                    lock: cocina_object.lock,
                    immutable: false)
  end
end
