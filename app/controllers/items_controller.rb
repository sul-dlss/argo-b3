# frozen_string_literal: true

# Controller for items (DRO)
class ItemsController < ApplicationController
  include ApoOptionsConcern
  include EditCocinaObjectConcern
  include RegisterCancelConcern
  include TokenConcern

  # Matches ObjectsController so its descriptive CSV download accepts the druid token.
  self.token_purpose = 'show'

  edit_form EditItemForm

  # Values for submit buttons
  DRAFT_VALUE = 'draft'
  DRAFT_TO_ADD_FILES_VALUE = 'add_files'
  DEPOSIT_VALUE = 'deposit'

  def new
    authorize! with: ItemPolicy

    @new_item_form = NewItemForm.new
    @cancel_path = register_cancel_path

    set_apo_and_collection_options(form: @new_item_form)
  end

  def edit
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.draft_editable?

    @edit_item_form = prefilled_edit_form
    set_edit_view
  end

  def create
    @new_item_form = NewItemForm.new(new_item_form_params)
    authorize! @new_item_form, with: ItemPolicy

    if @new_item_form.valid?
      @new_item_form.create!(user_name: current_user.sunetid)
      flash[:toast] = t('edit.items.new.toasts.register')
      redirect_to create_redirect_path
    else
      @cancel_path = root_path
      set_apo_and_collection_options(form: @new_item_form)
      render :new, status: :unprocessable_content
    end
  end

  def update # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.draft_editable?

    @edit_item_form = submitted_edit_form
    return redirect_stale if @edit_item_form.stale?
    return redirect_assembly_stopped_with_error if deposit? && version_service.assembly_stopped_with_error?

    # The mutable Content holds the OCR settings and must follow the object to its new lock.
    @edit_item_form.content = Content.mutable_for(@cocina_object)
    return redirect_content_busy if @edit_item_form.content&.staging_or_discovering?

    authorize! @edit_item_form, to: :add_to_collections?, with: ItemPolicy
    authorize! @edit_item_form, to: :update_apo?, with: ItemPolicy
    return render_invalid_edit unless @edit_item_form.valid?(deposit? ? :deposit : nil)

    @edit_item_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_updated
  end

  private

  def new_item_form_params
    NewItemForm.params_from(params)
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

  def set_edit_view
    @title = CocinaSupport.title(@cocina_object)
    # Computed once, since every pane's footer renders the discard or purge button.
    @draft_actions_presenter = DraftActionsPresenter.new(cocina_version: @cocina_object.version, version_service:)
    @druid_token = generate_token(@druid)
    set_apo_and_collection_options(form: @edit_item_form)
  end

  def set_apo_and_collection_options(form:)
    @apo_options = apo_options(current_apo_druid: form.previous_cocina_object&.administrative&.hasAdminPolicy)
    # Only the selected collections are options, since other options are loaded as the user types.
    druids = form.collection_druids
    titles = Searchers::CollectionListByDruid.call(druids:).to_h(&:reverse)
    @collection_options = druids.map { |druid| [titles[druid] || DruidSupport.bare_druid_from(druid), druid] }
  end

  def create_redirect_path
    if params[:commit] == DRAFT_TO_ADD_FILES_VALUE
      edit_content_path(@new_item_form.druid)
    else
      object_path(@new_item_form.druid)
    end
  end
end
