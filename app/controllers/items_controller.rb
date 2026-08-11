# frozen_string_literal: true

# Controller for items (DRO)
class ItemsController < ApplicationController
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
      redirect_to object_path(@item_form.druid)
    else
      set_apo_options
      render :new, status: :unprocessable_content
    end
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
end
