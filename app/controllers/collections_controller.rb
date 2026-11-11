# frozen_string_literal: true

# Controller for registering, editing, and depositing collections
class CollectionsController < ApplicationController
  include ApoOptionsConcern
  include RegisterCancelConcern
  include TokenConcern

  # Matches ObjectsController so its descriptive CSV download accepts the druid token.
  self.token_purpose = 'show'

  before_action :set_druid_and_cocina_object, only: %i[edit update]

  # Renders the form for registering and depositing a collection.
  # @return [void]
  def new
    authorize! with: CollectionPolicy

    @new_collection_form = NewCollectionForm.new
    @cancel_path = register_cancel_path
    set_new_apo_options(form: @new_collection_form)
  end

  # Renders the form for editing and depositing a collection.
  # @return [void]
  def edit
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @edit_collection_form = EditCollectionForm.build_from_cocina_object(@cocina_object)
    @edit_collection_form.version_service = version_service
    @edit_collection_form.prefill_version_description
    set_edit_apo_options(form: @edit_collection_form)
    set_edit_view
  end

  # Registers and deposits a collection, or re-renders the form if it is invalid.
  # @return [void]
  def create
    @new_collection_form = NewCollectionForm.new(new_collection_form_params)
    # to_s, since a nil record would be replaced by ActionPolicy's implicit target.
    authorize! @new_collection_form.apo_druid.to_s, with: CollectionPolicy

    set_new_apo_options(form: @new_collection_form)
    return render_invalid unless @new_collection_form.valid?

    @new_collection_form.create!(user_name: current_user.sunetid)
    redirect_to object_path(@new_collection_form.druid), flash: { toast: t('edit.collections.new.toasts.register') }
  end

  # Saves and deposits a collection, or re-renders the form if it is invalid.
  # @return [void]
  def update
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?
    return redirect_stale if stale?

    @edit_collection_form = build_submitted_edit_collection_form
    authorize! @edit_collection_form, to: :update_apo?, with: CollectionPolicy
    return render_invalid_edit unless @edit_collection_form.valid?

    # A collection cannot be saved as a draft, so editing it always deposits it.
    @edit_collection_form.save!(user_name: current_user.sunetid)
    redirect_to object_path(@druid), flash: { toast: t('edit.collections.edit.toasts.deposited') }
  end

  private

  # @return [ActionController::Parameters]
  def new_collection_form_params
    NewCollectionForm.params_from(params)
  end

  # @return [ActionController::Parameters]
  def edit_collection_form_params
    EditCollectionForm.params_from(params)
  end

  # @return [void]
  def render_invalid
    @cancel_path = root_path
    render :new, status: :unprocessable_content
  end

  # Only APOs the user can edit may govern a new collection, so they are both the options and what the form
  # accepts.
  # @param form [NewCollectionForm]
  # @return [void]
  def set_new_apo_options(form:)
    @apo_options = Searchers::AdminPolicyList.call(user_scope: current_user_scope, editable: true)
    form.selectable_apo_druids = @apo_options.map(&:last)
  end

  # The APOs the user can edit, plus the collection's current APO so that a user who can edit the collection
  # but not its APO can keep it; these are both the options and what the form accepts.
  # @param form [EditCollectionForm]
  # @return [void]
  def set_edit_apo_options(form:)
    @apo_options = apo_options(current_apo_druid: @cocina_object.administrative.hasAdminPolicy)
    form.selectable_apo_druids = @apo_options.map(&:last)
  end

  def build_submitted_edit_collection_form
    EditCollectionForm.build_from_cocina_object(@cocina_object).tap do |form|
      form.version_service = version_service
      form.update(edit_collection_form_params)
      set_edit_apo_options(form:)
    end
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { danger: t('edit.collections.edit.warnings.not_editable') }
  end

  # The lock changes whenever the object is updated, so a different (or missing) lock means that the object
  # was changed after the edit page was loaded.
  def stale?
    edit_collection_form_params[:lock] != @cocina_object.lock
  end

  def redirect_stale
    redirect_to edit_collection_path(@druid), flash: { danger: t('edit.collections.edit.warnings.stale') }
  end

  def set_edit_view
    @title = CocinaSupport.title(@cocina_object)
    @druid_token = generate_token(@druid)
  end

  def render_invalid_edit
    set_edit_view
    render :edit, status: :unprocessable_content
  end

  def set_druid_and_cocina_object
    @druid = params[:id]
    @cocina_object = Sdr::Repository.find(druid: @druid)
  end
end
