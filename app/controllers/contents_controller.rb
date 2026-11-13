# frozen_string_literal: true

# Controller for managing content (structural): the steps of managing files (see Contents::ManageFilesFlow).
class ContentsController < ContentsApplicationController
  skip_verify_authorized only: %i[show]
  before_action :set_editable_cocina_object, only: %i[edit update]

  # Values for submit buttons, which are rendered by Item::ManageFilesStepFooterComponent and the structure step.
  DEPOSIT_VALUE = ItemsController::DEPOSIT_VALUE
  DRAFT_VALUE = ItemsController::DRAFT_VALUE
  NEXT_VALUE = 'next'
  PREVIOUS_VALUE = 'previous'
  RESTRUCTURE_VALUE = 'restructure'
  CSV_VALUE = 'csv'

  def show
    @content_token = params[:id]
    verified_content_id = verify_token(@content_token)
    @content = Content.with_structural_associations.find(verified_content_id)
  end

  def edit
    cocina_object = @cocina_object
    content = Contents::Builder.find_or_create(cocina_object:, immutable: false)
    @contents_item_form = ContentsItemForm.for_manage_files(cocina_object, version_service:, content:)
    set_step_page(cocina_object:, content:)
    return render :wait if content.discovering? || content.structuring?

    # Shows the errors when depositing from elsewhere (e.g., the status box) found them.
    @manage_files_flow.go_to_deposit_errors!(@contents_item_form) if params[:deposit].present?
    @structuring_result = content.take_structuring_result! if @manage_files_flow.structure_step?
    render_step(cocina_object:, content:)
  end

  def update
    druid = params[:id]
    cocina_object = @cocina_object
    # The content was built for the lock when the edit page was loaded, so it is missing if the object has changed.
    content = Content.mutable_for(cocina_object)
    return redirect_stale(druid:) if content.nil?
    # E.g., submitted twice while structuring, which the edit page shows.
    return redirect_to edit_content_path(druid) if content.busy?

    @contents_item_form = ContentsItemForm.for_manage_files(cocina_object, version_service:, content:,
                                                                           params: ContentsItemForm.params_from(params))
    @manage_files_flow = build_manage_files_flow(cocina_object:, content:)
    submit(cocina_object:, content:)
  end

  private

  def set_editable_cocina_object
    druid = params[:id]
    @cocina_object = Sdr::Repository.find(druid:)
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable(druid:) unless version_service.draft_editable?

    redirect_staging(druid:) if staging?(druid:)
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: params[:id])
  end

  def deposit?
    params[:commit] == DEPOSIT_VALUE
  end

  # Performs the submit button's action.
  def submit(cocina_object:, content:)
    case params[:commit]
    when NEXT_VALUE then next_step(cocina_object:, content:)
    when PREVIOUS_VALUE then previous_step(druid: content.druid)
    when RESTRUCTURE_VALUE then restructure(content:)
    when CSV_VALUE then upload_csv(cocina_object:, content:)
    else save_or_deposit(cocina_object:, content:)
    end
  end

  def next_step(cocina_object:, content:)
    unless @manage_files_flow.current_step_complete?(@contents_item_form)
      return render_invalid_step(cocina_object:, content:)
    end

    @manage_files_flow.next!(@contents_item_form)
    redirect_to edit_content_path(content.druid)
  end

  def previous_step(druid:)
    @manage_files_flow.previous!(@contents_item_form)
    redirect_to edit_content_path(druid)
  end

  def restructure(content:)
    content.start_structuring!(append: false)
    redirect_to edit_content_path(content.druid)
  end

  # Replaces the structure with the uploaded CSV. Nothing is changed unless the CSV is entirely valid.
  def upload_csv(cocina_object:, content:)
    @structural_csv_form = StructuralCsvForm.new(StructuralCsvForm.params_from(params))
    @structural_csv_form.replace_structure(content:)
    return render_invalid_step(cocina_object:, content:) if @structural_csv_form.errors.any?

    redirect_to edit_content_path(content.druid), flash: { toast: t('edit.contents.structure.toasts.csv') }
  end

  def save_or_deposit(cocina_object:, content:)
    druid = cocina_object.externalIdentifier
    return redirect_assembly_stopped_with_error(druid:) if deposit? && version_service.assembly_stopped_with_error?

    # Depositing additionally validates the content (see ContentsItemForm).
    unless @contents_item_form.valid?(deposit? ? :deposit : nil)
      @manage_files_flow.go_to_first_error!(@contents_item_form.errors)
      return render_invalid_step(cocina_object:, content:)
    end
    return render_save_failed(content:) unless save_and_stage(content:)

    redirect_staging_started(druid:)
  end

  # @return [Boolean] false if saving to SDR failed
  def save_and_stage(content:)
    # Saving also saves the content's text extraction settings, resets its flow, and rebases it onto the new lock.
    @contents_item_form.save!(user_name: current_user.sunetid)
    content.start_staging!(user: current_user, accession: deposit?)
    true
  rescue Sdr::Repository::Error => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e)
    false
  end

  def redirect_assembly_stopped_with_error(druid:)
    redirect_to object_path(druid), flash: { warning: t('edit.items.edit.warnings.assembly_stopped_with_error') }
  end

  def redirect_not_editable(druid:)
    redirect_to object_path(druid), flash: { danger: t('edit.items.edit.warnings.not_editable') }
  end

  # Staging may have moved the content to a new lock, so it is found by druid.
  def staging?(druid:)
    Content.latest_staging_activity(druid:)&.staging?
  end

  def redirect_staging(druid:)
    redirect_to object_path(druid), flash: { danger: t('edit.contents.edit.warnings.staging') }
  end

  def redirect_staging_started(druid:)
    redirect_to object_path(druid), flash: { toast: t('edit.items.new.toasts.staging_started') }
  end

  def redirect_stale(druid:)
    redirect_to edit_content_path(druid), flash: { toast: t('edit.contents.edit.toasts.stale') }
  end

  def render_invalid_step(cocina_object:, content:)
    set_step_page(cocina_object:, content:)
    render_step(cocina_object:, content:, status: :unprocessable_content)
  end

  # The form may have opened a version before failing, so the page is rebuilt from the form's current object.
  def render_save_failed(content:)
    flash.now[:danger] = t('edit.contents.edit.errors.save_failed')
    render_invalid_step(cocina_object: @contents_item_form.previous_cocina_object, content: content.reload)
  end

  def render_step(cocina_object:, content:, status: :ok)
    set_structure_step(cocina_object:, content:) if @manage_files_flow.structure_step?
    render @manage_files_flow.current_step, status:
  end

  def set_step_page(cocina_object:, content:)
    cache_cocina_hash(cocina_object:)
    @content = content
    @solr_doc = SolrDocPresenter.new(solr_doc: Sdr::Repository.find_solr(druid: cocina_object.externalIdentifier))
    @content_token = generate_token(content.id)
    @content_form = ContentForm.new
    @manage_files_flow ||= build_manage_files_flow(cocina_object:, content:)
    # Computed once, since every step's footer renders the discard or purge button.
    @draft_actions_presenter = DraftActionsPresenter.new(cocina_version: cocina_object.version, version_service:,
                                                         purge_label: t('edit.contents.edit.buttons.purge'))
  end

  # The structure is rendered with its resources and the populator that structuring would use.
  def set_structure_step(cocina_object:, content:)
    @content = Content.with_structural_associations.find(content.id)
    @structural_csv_form ||= StructuralCsvForm.new
    @populator_selection = Contents::PopulatorSelector.call(content: @content,
                                                            cocina_object: content.with_selected_access(cocina_object),
                                                            content_type: content.selected_content_type(cocina_object))
  end

  def build_manage_files_flow(cocina_object:, content:)
    Contents::ManageFilesFlow.new(content:, agreement: CocinaSupport.agreement?(cocina_object))
  end
end
