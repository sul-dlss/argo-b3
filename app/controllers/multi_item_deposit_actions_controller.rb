# frozen_string_literal: true

# Controller for Multi-Item Deposits.
class MultiItemDepositActionsController < ApplicationController
  NEXT_VALUE = 'next'
  PREVIOUS_VALUE = 'previous'

  before_action :set_multi_item_deposit_action, only: %i[edit update structural_metadata_csv_template]

  def edit
    authorize! @multi_item_deposit_action

    return render :wait if @multi_item_deposit_action.discovering? || @multi_item_deposit_action.structuring?

    if @multi_item_deposit_action.discovery_step?
      @discovery_form = MultiItemDeposit::DiscoveryForm.from_model(@multi_item_deposit_action)
      return render :discovery
    end

    if @multi_item_deposit_action.structure_step?
      @structure_form = MultiItemDeposit::StructureForm.from_model(@multi_item_deposit_action)
      return render :structure
    end

    # Stubbing this out for now.
    return render :deposit if @multi_item_deposit_action.deposit_step?

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
    return update_structure if @multi_item_deposit_action.structure_step?

    # Can be removed once all of the edit views are implemented.
    raise NotImplementedError, "Editing #{@multi_item_deposit_action.step} step is not yet implemented"
  end

  def structural_metadata_csv_template
    authorize! @multi_item_deposit_action, to: :edit?

    send_data StructuralCsv::Template.as_csv(multi_item_deposit_action: @multi_item_deposit_action),
              type: 'text/csv', filename: MultiItemDepositAction::STRUCTURAL_METADATA_CSV_FILENAME
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

  def update_structure
    # Structuring cannot be restarted while in progress, e.g., after a double submit.
    if @multi_item_deposit_action.structuring?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
    end
    return return_to_discovery if params[:commit] == PREVIOUS_VALUE
    return proceed_to_deposit if params[:commit] == NEXT_VALUE

    @structure_form = build_submitted_structure_form
    return render :structure, status: :unprocessable_content unless @structure_form.valid?

    MultiItemDeposit::StructureStarter.call(multi_item_deposit_action: @multi_item_deposit_action,
                                            structure_form: @structure_form)
    redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
  end

  def proceed_to_structure
    @multi_item_deposit_action.update!(step: :structure) if @multi_item_deposit_action.discovery_succeeded?
    redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
  end

  def build_submitted_structure_form
    MultiItemDeposit::StructureForm.new(structure_form_params.with_defaults(saved_structural_metadata_csv_params))
                                   .tap { |form| form.multi_item_deposit_action = @multi_item_deposit_action }
  end

  def return_to_discovery
    @multi_item_deposit_action.update!(step: :discovery)
    redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
  end

  def proceed_to_deposit
    @multi_item_deposit_action.update!(step: :deposit) if @multi_item_deposit_action.structuring_succeeded?
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

  # A saved uploaded structural metadata CSV is used for an upload unless another CSV is provided.
  def saved_structural_metadata_csv_params
    return {} unless @multi_item_deposit_action.structural_metadata_csv_source_upload?

    { structural_metadata_csv: @multi_item_deposit_action.structural_metadata_csv }
  end

  def structure_form_params
    MultiItemDeposit::StructureForm.params_from(params)
  end
end
