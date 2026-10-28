# frozen_string_literal: true

# Controller for items (DRO)
class ItemsController < ApplicationController
  include TokenConcern

  # Matches ObjectsController so its descriptive CSV download accepts the druid token.
  self.token_purpose = 'show'

  before_action :set_druid_and_cocina_object, only: %i[edit update]
  # Values for submit buttons
  DRAFT_VALUE = 'draft'
  DRAFT_TO_ADD_FILES_VALUE = 'add_files'
  DEPOSIT_VALUE = 'deposit'

  def new
    authorize! with: ItemPolicy

    @new_item_form = NewItemForm.new
    @cancel_path = (request.referer if request.referer.present? && request.referer.exclude?(new_item_path)) || root_path

    set_apo_and_collection_options(form: @new_item_form)
  end

  def edit
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @edit_item_form = EditItemForm.build_from_cocina_object(@cocina_object)
    @edit_item_form.version_service = version_service
    @edit_item_form.prefill_version_description
    set_edit_view
  end

  def create
    authorize! with: ItemPolicy

    @new_item_form = NewItemForm.new(new_item_form_params)

    if @new_item_form.valid?
      @new_item_form.create!(user_name: current_user.sunetid)
      flash[:toast] = t('edit.items.new.toasts.register')
      redirect_to create_redirect_path
    else
      set_apo_and_collection_options(form: @new_item_form)
      render :new, status: :unprocessable_content
    end
  end

  def update # rubocop:disable Metrics/AbcSize
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?
    return redirect_stale if stale?

    # The mutable Content holds the OCR settings and must follow the object to its new lock.
    @content = Content.mutable_for(@cocina_object)
    return redirect_content_busy if @content&.staging_or_discovering?

    @edit_item_form = build_submitted_edit_item_form
    return render_invalid_edit unless @edit_item_form.valid?

    @edit_item_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_updated
  end

  private

  def new_item_form_params
    NewItemForm.params_from(params)
  end

  def build_submitted_edit_item_form
    EditItemForm.build_from_cocina_object(@cocina_object).tap do |form|
      form.version_service = version_service
      form.update(edit_item_form_params)
      form.content = @content
    end
  end

  def edit_item_form_params
    EditItemForm.params_from(params)
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  def deposit?
    params[:commit] == DEPOSIT_VALUE
  end

  def redirect_updated
    toast_key = deposit? ? 'deposited' : 'updated'
    redirect_to update_redirect_path, flash: { toast: t("edit.items.edit.toasts.#{toast_key}") }
  end

  def update_redirect_path
    params[:commit] == DRAFT_TO_ADD_FILES_VALUE ? edit_content_path(@druid) : object_path(@druid)
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { warning: t('edit.items.edit.warnings.not_editable') }
  end

  # The lock changes whenever the object is updated, so a different (or missing) lock means that the object
  # was changed after the edit page was loaded.
  def stale?
    edit_item_form_params[:lock] != @cocina_object.lock
  end

  def redirect_stale
    redirect_to edit_item_path(@druid), flash: { warning: t('edit.items.edit.warnings.stale') }
  end

  def redirect_content_busy
    redirect_to edit_item_path(@druid), flash: { warning: t('edit.items.edit.warnings.content_busy') }
  end

  def set_edit_view
    @title = Cocina::Models::Builders::TitleBuilder.build(@cocina_object.description.title)
    # Computed once, since every pane's footer renders the discard or purge button.
    @discard_or_purge_presenter = DiscardOrPurgePresenter.new(cocina_version: @cocina_object.version, version_service:)
    @druid_token = generate_token(@druid)
    set_apo_and_collection_options(form: @edit_item_form)
  end

  def render_invalid_edit
    set_edit_view
    render :edit, status: :unprocessable_content
  end

  def set_apo_and_collection_options(form:)
    @apo_options = apo_options(apo_druid: form.apo_druid)
    # Only the selected collections are options, since other options are loaded as the user types.
    druids = form.collection_druids
    titles = Searchers::CollectionListByDruid.call(druids:).to_h(&:reverse)
    @collection_options = druids.map { |druid| [titles[druid] || DruidSupport.bare_druid_from(druid), druid] }
  end

  # The current APO is always an option (even if the user cannot otherwise select it),
  # so that saving an edit does not change it.
  def apo_options(apo_druid:)
    options = Searchers::AdminPolicyList.call(user_scope: current_user_scope)
    return options if apo_druid.blank? || options.any? { |_title, druid| druid == apo_druid }

    [[apo_title(apo_druid:), apo_druid]] + options
  end

  # Falls back to the bare druid if the APO is not found.
  def apo_title(apo_druid:)
    titles = Searchers::AdminPolicyListByDruid.call(druids: [apo_druid]).to_h(&:reverse)
    titles[apo_druid] || DruidSupport.bare_druid_from(apo_druid)
  end

  def create_redirect_path
    if params[:commit] == DRAFT_TO_ADD_FILES_VALUE
      edit_content_path(@new_item_form.druid)
    else
      object_path(@new_item_form.druid)
    end
  end

  def set_druid_and_cocina_object
    @druid = params[:id]
    @cocina_object = Sdr::Repository.find(druid: @druid)
  end
end
