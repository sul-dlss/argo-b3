# frozen_string_literal: true

# Controller for items (DRO)
class ItemsController < ApplicationController
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

  def update
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?
    return redirect_stale if stale?

    @edit_item_form = build_submitted_edit_item_form
    return render_invalid_edit unless @edit_item_form.valid?

    @edit_item_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_updated
  end

  private

  def new_item_form_params
    param_key = NewItemForm.model_name.param_key
    params.permit(param_key => NewItemForm.permitted_params)[param_key]
  end

  def build_submitted_edit_item_form
    EditItemForm.build_from_cocina_object(@cocina_object).tap do |form|
      form.version_service = version_service
      form.update(edit_item_form_params)
    end
  end

  def edit_item_form_params
    param_key = EditItemForm.model_name.param_key
    params.permit(param_key => EditItemForm.permitted_params)[param_key] || {}
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  def deposit?
    params[:commit] == DEPOSIT_VALUE
  end

  def redirect_updated
    toast_key = deposit? ? 'deposited' : 'updated'
    redirect_to object_path(@druid), flash: { toast: t("edit.items.edit.toasts.#{toast_key}") }
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

  def set_edit_view
    @title = Cocina::Models::Builders::TitleBuilder.build(@cocina_object.description.title)
    @cancel_path = object_path(@druid)
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
