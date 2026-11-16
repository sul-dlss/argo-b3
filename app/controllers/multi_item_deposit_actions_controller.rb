# frozen_string_literal: true

# Controller for Multi-Item Deposits.
# It drives the deposit's three steps and their downloads, which keeps it slightly over the class length limit.
class MultiItemDepositActionsController < ApplicationController # rubocop:disable Metrics/ClassLength
  NEXT_VALUE = 'next'
  PREVIOUS_VALUE = 'previous'
  PER_PAGE = 20

  before_action :set_multi_item_deposit_action, only: %i[edit update destroy structural_metadata_csv_template
                                                         discovery_report structure_report]
  skip_verify_authorized only: %i[index]

  def index
    @filter_form = MultiItemDeposit::FilterForm.new(filter_form_params,
                                                    user: Current.user,
                                                    admin: allowed_to?(:admin?, nil, with: AdminPolicy))
    @multi_item_deposit_actions = authorized_scope(MultiItemDepositAction.all)
                                  .filtered(**@filter_form.filters)
                                  .includes(:user)
                                  .order(updated_at: :desc, id: :desc)
                                  .page(params[:page]).per(PER_PAGE)
  end

  def show
    @multi_item_deposit_action = MultiItemDepositAction.includes(item_deposit_actions: :content)
                                                       .order(item_deposit_actions: { manifest_line_number: :asc })
                                                       .find(params.expect(:id))
    authorize! @multi_item_deposit_action

    unless @multi_item_deposit_action.submitted_step?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
    end

    @object_status_presenters = MultiItemDeposit::ObjectStatusPresentersBuilder.call(
      item_deposit_actions: @multi_item_deposit_action.item_deposit_actions,
      initiating: @multi_item_deposit_action.initiating_depositing?
    )
  end

  def edit
    authorize! @multi_item_deposit_action

    return render :wait if wait?

    if @multi_item_deposit_action.discovery_step?
      @discovery_form = MultiItemDeposit::DiscoveryForm.from_model(@multi_item_deposit_action)
      return render :discovery
    end

    if @multi_item_deposit_action.structure_step?
      @structure_form = MultiItemDeposit::StructureForm.from_model(@multi_item_deposit_action)
      return render :structure
    end

    if @multi_item_deposit_action.deposit_step?
      @deposit_form = MultiItemDeposit::DepositForm.from_model(@multi_item_deposit_action)
      return render :deposit
    end

    # Otherwise, submitted so redirect to show page
    redirect_to multi_item_deposit_action_path(@multi_item_deposit_action)
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

    # Otherwise, deposit step.
    update_deposit
  end

  # A stale tab may discard a deposit that has since started a step or been submitted; the edit page then shows it.
  def destroy
    authorize! @multi_item_deposit_action

    unless @multi_item_deposit_action.discardable?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action),
                         flash: { warning: t('edit.multi_item_deposits.warnings.not_discardable') }
    end

    @multi_item_deposit_action.discard!
    redirect_to root_path, status: :see_other, flash: { toast: t('edit.multi_item_deposits.toasts.discarded') }
  end

  def structural_metadata_csv_template
    authorize! @multi_item_deposit_action, to: :edit?

    send_data StructuralCsv::Template.as_csv(multi_item_deposit_action: @multi_item_deposit_action),
              type: 'text/csv', filename: MultiItemDepositAction::STRUCTURAL_METADATA_CSV_FILENAME
  end

  # The report of the results of checking the manifest (discovery).
  def discovery_report
    authorize! @multi_item_deposit_action, to: :edit?

    # The page links to the report only once checking has completed, but a link in a stale tab may be followed
    # while checking is rerunning, when the report would be incomplete. The edit page then shows checking in progress.
    if @multi_item_deposit_action.discovery_completed_at.blank?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
    end

    send_data DiscoveryReportCsv::Export.as_csv(multi_item_deposit_action: @multi_item_deposit_action),
              type: 'text/csv', filename: "multi_item_deposit_#{@multi_item_deposit_action.id}_discovery_report.csv"
  end

  # The report of the results of checking files (structuring).
  def structure_report
    authorize! @multi_item_deposit_action, to: :edit?

    # As for the discovery report, a stale tab may link to it while checking is rerunning.
    if @multi_item_deposit_action.structuring_completed_at.blank?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
    end

    send_data StructureReportCsv::Export.as_csv(multi_item_deposit_action: @multi_item_deposit_action),
              type: 'text/csv', filename: "multi_item_deposit_#{@multi_item_deposit_action.id}_structure_report.csv"
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

  def update_deposit
    # Initiating the deposit cannot be restarted while in progress, e.g., after a double submit.
    if @multi_item_deposit_action.initiating_depositing?
      return redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
    end
    return return_to_structure if params[:commit] == PREVIOUS_VALUE

    @deposit_form = build_submitted_deposit_form
    return render :deposit, status: :unprocessable_content unless @deposit_form.valid?

    MultiItemDeposit::DepositStarter.call(multi_item_deposit_action: @multi_item_deposit_action,
                                          deposit_form: @deposit_form,
                                          effective_groups: current_effective_groups)
    redirect_to edit_multi_item_deposit_action_path(@multi_item_deposit_action)
  end

  def build_submitted_deposit_form
    MultiItemDeposit::DepositForm.new(deposit_form_params)
                                 .tap { |form| form.multi_item_deposit_action = @multi_item_deposit_action }
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

  # The deposit results are cleared, since they would be out of date when returning to the deposit step.
  def return_to_structure
    @multi_item_deposit_action.update!(step: :structure, initiating_deposit_completed_at: nil)
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

  def filter_form_params
    MultiItemDeposit::FilterForm.params_from(params)
  end

  # The deposit (e.g., its Globus path) is provided by the controller, not the submitted params.
  def discovery_form_params
    MultiItemDeposit::DiscoveryForm.params_from(params).merge(multi_item_deposit_action: @multi_item_deposit_action)
  end

  # A saved uploaded structural metadata CSV is used for an upload unless another CSV is provided.
  def saved_structural_metadata_csv_params
    return {} unless @multi_item_deposit_action.structural_metadata_csv_source_upload?

    { structural_metadata_csv: @multi_item_deposit_action.structural_metadata_csv }
  end

  def structure_form_params
    MultiItemDeposit::StructureForm.params_from(params)
  end

  def deposit_form_params
    MultiItemDeposit::DepositForm.params_from(params)
  end

  def wait?
    @multi_item_deposit_action.discovering? || @multi_item_deposit_action.structuring? ||
      @multi_item_deposit_action.initiating_depositing?
  end
end
