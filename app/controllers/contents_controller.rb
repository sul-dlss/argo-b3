# frozen_string_literal: true

# Controller for managing content (structural)
class ContentsController < ContentsApplicationController
  skip_verify_authorized only: %i[show]

  def show
    @content_token = params[:id]
    verified_content_id = verify_token(@content_token)
    @content = Content.with_structural_associations.find(verified_content_id)
  end

  def edit
    druid = params[:id]
    cocina_object = Sdr::Repository.find(druid:)
    cache_cocina_hash(cocina_object:)
    authorize! cocina_object, with: ItemPolicy

    @contents_item_form = ContentsItemForm.build_from_cocina_object(cocina_object)
    set_edit_form(cocina_object:, content: find_or_create_content(cocina_object:))
  end

  def update
    druid = params[:id]
    cocina_object = Sdr::Repository.find(druid:)
    authorize! cocina_object, with: ItemPolicy

    # The content was built for the lock when the edit page was loaded, so it is missing if the object has changed.
    content = find_content(cocina_object:)
    return redirect_to edit_content_path(druid), flash: { toast: t('edit.contents.edit.toasts.stale') } if content.nil?

    @contents_item_form = build_submitted_contents_item_form(cocina_object:)
    return render_invalid_edit(cocina_object:, content:) unless @contents_item_form.valid?

    save_and_stage(content:)
    redirect_to object_path(druid), flash: { toast: t('edit.items.new.toasts.staging_started') }
  end

  private

  def render_invalid_edit(cocina_object:, content:)
    cache_cocina_hash(cocina_object:)
    set_edit_form(cocina_object:, content:)
    render :edit, status: :unprocessable_content
  end

  def save_and_stage(content:)
    @contents_item_form.save!(user_name: current_user.sunetid)
    # Saving changes the lock, which staging checks against the content's lock.
    content.update!(lock: @contents_item_form.previous_cocina_object.lock)

    content.staging_started!
    StageFilesJob.perform_later(content:, accession: params[:commit] == ItemsController::DEPOSIT_VALUE,
                                user: current_user)
  end

  def set_edit_form(cocina_object:, content:)
    @content = content
    @solr_doc = fetch_solr_doc(druid: cocina_object.externalIdentifier)
    @content_token = generate_token(@content.id)
    @content_form = ContentForm.new
  end

  def build_submitted_contents_item_form(cocina_object:)
    ContentsItemForm.build_from_cocina_object(cocina_object).tap { |form| form.update(contents_item_form_params) }
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
