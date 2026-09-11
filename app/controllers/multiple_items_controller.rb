# frozen_string_literal: true

# Controller for registering multiple items (DRO)
class MultipleItemsController < ApplicationController
  def new
    authorize! with: ItemPolicy

    @items_registration_form = ItemsRegistrationForm.new
    set_apo_options
  end

  def create
    authorize! with: ItemPolicy

    @items_registration_form = ItemsRegistrationForm.new(items_registration_form_params)

    if @items_registration_form.valid?
      create_bulk_action
      @bulk_action.enqueue_job(items_registration_form: @items_registration_form)
      flash[:toast] = "#{bulk_action_config.label} submitted"
      redirect_to bulk_actions_path
    else
      set_apo_options
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_apo_options
    @apo_options = Searchers::AdminPolicyList.call
  end

  def items_registration_form_params
    params.permit(items_registration: ItemsRegistrationForm.permitted_params)[:items_registration]
  end

  def bulk_action_config
    BulkActions::REGISTER_FORM
  end

  def create_bulk_action
    @bulk_action = BulkAction.create!(
      action_type: bulk_action_config.action_type,
      user: current_user
    )
  end
end
