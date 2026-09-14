# frozen_string_literal: true

# Controller for registering multiple items (DRO)
# Note that registering multiple items uses an asynchronous flow for form validation.
# 1. The user submits the form, which creates a FormValidationAction record which includes a serialization of the form.
# 2. A ValidateFormJob is enqueued to validate the form asynchronously.
# 3. The user is redirected to the show page for the FormValidationAction, which polls the status of the
#    form validation.
# 4. When the form validation is complete, the user is redirected if valid,
#    or shown the form with errors if invalid.
class MultipleItemsController < ApplicationController
  def show # rubocop:disable Metrics/AbcSize
    form_validation_action = FormValidationAction.find(params.expect(:id))
    authorize! form_validation_action, with: MultipleItemsPolicy

    @items_registration_form = form_validation_action.form

    case form_validation_action.status
    when 'valid'
      bulk_action = enqueue_bulk_action
      flash[:toast] = "#{bulk_action_config.label} submitted"
      redirect_to bulk_action_path(bulk_action)
    when 'invalid', 'failed'
      set_apo_options
      flash.now[:warning] = I18n.t('edit.multiple_items.errors.failed') if form_validation_action.status_failed?
      render :new, status: :unprocessable_content
    else
      render :show
    end
  end

  def new
    authorize! with: ItemPolicy

    @items_registration_form = ItemsRegistrationForm.new
    set_apo_options
  end

  def create
    authorize! with: ItemPolicy

    @items_registration_form = ItemsRegistrationForm.new(items_registration_form_params)

    form_validation_action = FormValidationAction.create!(user: current_user, form: @items_registration_form,
                                                          status: 'queued')

    ValidateFormJob.perform_later(form_validation_action:)

    redirect_to multiple_item_path(form_validation_action.id)
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

  def enqueue_bulk_action
    bulk_action = BulkAction.create!(
      action_type: bulk_action_config.action_type,
      user: current_user
    )
    bulk_action.enqueue_job(items_registration_form: @items_registration_form)
    bulk_action
  end
end
