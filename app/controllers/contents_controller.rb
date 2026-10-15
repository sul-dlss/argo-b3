# frozen_string_literal: true

# Controller for managing content (structural)
class ContentsController < ContentsApplicationController
  skip_verify_authorized only: %i[show]

  # Values for submit buttons
  DEPOSIT_VALUE = 'deposit'
  DRAFT_VALUE = 'draft'

  def show
    @content_token = params[:id]
    verified_content_id = verify_token(@content_token)
    @content = Content.with_structural_associations.find(verified_content_id)
  end

  def edit
    druid = params[:id]
    cocina_object = Sdr::Repository.find(druid:)
    authorize! cocina_object, with: ObjectPolicy
    return redirect_not_editable(druid:) unless version_service.editable?

    cache_cocina_hash(cocina_object:)
    @contents_item_form = ContentsItemForm.build_from_cocina_object(cocina_object)
    @contents_item_form.version_service = version_service
    @contents_item_form.prefill_version_description
    set_edit_form(cocina_object:, content: find_or_create_content(cocina_object:))
  end

  def update
    druid = params[:id]
    cocina_object = Sdr::Repository.find(druid:)
    authorize! cocina_object, with: ObjectPolicy
    return redirect_not_editable(druid:) unless version_service.editable?

    # The content was built for the lock when the edit page was loaded, so it is missing if the object has changed.
    content = find_content(cocina_object:)
    return redirect_stale(druid:) if content.nil?

    @contents_item_form = build_submitted_contents_item_form(cocina_object:, content:)
    return render_invalid_edit(cocina_object:, content:) unless contents_item_form_valid?

    return render_save_failed(content:) unless save_and_stage(content:)

    redirect_staging_started(druid:)
  end

  private

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: params[:id])
  end

  def redirect_not_editable(druid:)
    redirect_to object_path(druid), flash: { warning: t('edit.items.edit.warnings.not_editable') }
  end

  def redirect_staging_started(druid:)
    redirect_to object_path(druid), flash: { toast: t('edit.items.new.toasts.staging_started') }
  end

  def redirect_stale(druid:)
    redirect_to edit_content_path(druid), flash: { toast: t('edit.contents.edit.toasts.stale') }
  end

  def render_invalid_edit(cocina_object:, content:)
    cache_cocina_hash(cocina_object:)
    set_edit_form(cocina_object:, content:)
    render :edit, status: :unprocessable_content
  end

  # The form may have opened a version before failing, so the page is rebuilt from the form's current object.
  def render_save_failed(content:)
    flash.now[:danger] = t('edit.contents.edit.errors.save_failed')
    render_invalid_edit(cocina_object: @contents_item_form.previous_cocina_object, content: content.reload)
  end

  # Depositing additionally validates the content (see ContentsItemForm).
  def contents_item_form_valid?
    @contents_item_form.valid?(params[:commit] == DEPOSIT_VALUE ? :deposit : nil)
  end

  # @return [Boolean] false if saving to SDR failed
  def save_and_stage(content:)
    # Saving also rebases the content onto the saved object's lock, which staging checks.
    @contents_item_form.save!(user_name: current_user.sunetid)

    content.clear_other_staging_failures!
    content.staging_started!
    StageFilesJob.perform_later(content:, accession: params[:commit] == ContentsController::DEPOSIT_VALUE,
                                user: current_user, workflow_context: @contents_item_form.workflow_context)
    true
  rescue Sdr::Repository::Error => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e)
    false
  end

  def set_edit_form(cocina_object:, content:)
    @content = content
    @solr_doc = fetch_solr_doc(druid: cocina_object.externalIdentifier)
    @content_token = generate_token(@content.id)
    @content_form = ContentForm.new
  end

  def build_submitted_contents_item_form(cocina_object:, content:)
    ContentsItemForm.build_from_cocina_object(cocina_object).tap do |form|
      form.version_service = version_service
      form.update(contents_item_form_params)
      form.content = content
    end
  end

  def contents_item_form_params
    params.permit(contents_item: ContentsItemForm.permitted_params)[:contents_item] || {}
  end

  def find_content(cocina_object:)
    Content.find_by(druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable: false)
  end

  def find_or_create_content(cocina_object:)
    Contents::Builder.find_or_create(cocina_object:, immutable: false)
  end

  def fetch_solr_doc(druid:)
    solr_doc = Sdr::Repository.find_solr(druid:)
    SolrDocPresenter.new(solr_doc:)
  end
end
