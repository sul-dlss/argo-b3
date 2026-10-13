# frozen_string_literal: true

# Controller for items (DRO)
class ItemsController < ApplicationController
  # Values for submit buttons
  DRAFT_VALUE = 'draft'
  DRAFT_TO_ADD_FILES_VALUE = 'add_files'

  def new
    authorize! with: ItemPolicy

    @new_item_form = NewItemForm.new
    @cancel_path = (request.referer if request.referer.present? && request.referer.exclude?(new_item_path)) || root_path

    set_apo_and_collection_options
  end

  def create
    authorize! with: ItemPolicy

    @new_item_form = NewItemForm.new(new_item_form_params)

    if @new_item_form.valid?
      @new_item_form.create!(user_name: current_user.sunetid)
      flash[:toast] = t('edit.items.new.toasts.register')
      redirect_to create_redirect_path
    else
      set_apo_and_collection_options
      render :new, status: :unprocessable_content
    end
  end

  private

  def new_item_form_params
    params.permit(item: NewItemForm.permitted_params)[:item]
  end

  def set_apo_and_collection_options
    @apo_options = Searchers::AdminPolicyList.call(user_scope: current_user_scope)
    # Only the selected collections are options, since other options are loaded as the user types.
    druids = @new_item_form.collection_druids
    titles = Searchers::CollectionListByDruid.call(druids:).to_h(&:reverse)
    @collection_options = druids.map { |druid| [titles[druid] || DruidSupport.bare_druid_from(druid), druid] }
  end

  def create_redirect_path
    if params[:commit] == DRAFT_TO_ADD_FILES_VALUE
      edit_content_path(@new_item_form.druid)
    else
      object_path(@new_item_form.druid)
    end
  end
end
