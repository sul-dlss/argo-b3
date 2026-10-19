# frozen_string_literal: true

# Controller for Multi-Item Deposits.
class MultiItemDepositActionsController < ApplicationController
  NEXT_VALUE = 'next'

  before_action :set_multi_item_deposit_action, only: %i[edit update]

  def edit
    authorize! @multi_item_deposit_action

    return render :wait if @multi_item_deposit_action.discovering?

    if @multi_item_deposit_action.discovery_step?
      @discovery_form = MultiItemDeposit::DiscoveryForm.from_model(@multi_item_deposit_action)
      return render :discovery
    end

    # Stubbing this out for now.
    return render :structure if @multi_item_deposit_action.structure_step?

    # Can be removed once all of the edit views are implemented.
    raise NotImplementedError, "Editing #{@multi_item_deposit_action.step} step is not yet implemented"
  end

  # Create is a POST (rather than a GET new) so that prefetching or reloading does not create a deposit.
  def create
    authorize! with: ItemPolicy, to: :new?

    multi_item_deposit_action = MultiItemDepositAction.create!(user: current_user)
    redirect_to edit_multi_item_deposit_action_path(multi_item_deposit_action)
  end

  def update
    authorize! @multi_item_deposit_action

    return update_discovery if @multi_item_deposit_action.discovery_step?

    # Can be removed once all of the edit views are implemented.
    raise NotImplementedError, "Editing #{@multi_item_deposit_action.step} step is not yet implemented"
  end

  private

  def update_discovery
    # Discovery cannot be restarted while in progress, e.g., after a double submit.
    if @multi_item_deposit_action.discovering?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
    end
    return proceed_to_structure if params[:commit] == NEXT_VALUE

    @discovery_form = MultiItemDeposit::DiscoveryForm.new(discovery_form_params.with_defaults(saved_manifest_params))
    return render :discovery, status: :unprocessable_content unless @discovery_form.valid?

    MultiItemDeposit::DiscoveryStarter.call(multi_item_deposit_action: @multi_item_deposit_action,
                                            discovery_form: @discovery_form,
                                            effective_groups: current_effective_groups)
    redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
  end

  def proceed_to_structure
    @multi_item_deposit_action.update!(step: :structure) if @multi_item_deposit_action.discovery_succeeded?
    redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
  end

  def set_multi_item_deposit_action
    @multi_item_deposit_action = MultiItemDepositAction.find(params.expect(:id))
  end

  # A saved uploaded manifest is used for an upload unless another manifest is provided.
  def saved_manifest_params
    return {} unless @multi_item_deposit_action.manifest_source_upload?

    { manifest_csv: @multi_item_deposit_action.manifest_csv }
  end

  def discovery_form_params
    MultiItemDeposit::DiscoveryForm.params_from(params)
  end
end
