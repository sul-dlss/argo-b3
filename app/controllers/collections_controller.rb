# frozen_string_literal: true

# Controller for registering, editing, and depositing collections
class CollectionsController < ApplicationController
  include ApoOptionsConcern
  include EditCocinaObjectConcern
  include RegisterCancelConcern
  include TokenConcern

  # Matches ObjectsController so its descriptive CSV download accepts the druid token.
  self.token_purpose = 'show'

  edit_form EditCollectionForm

  # Renders the form for registering and depositing a collection.
  # An apo_druid param (e.g., from the APO show page) preselects that APO, if the user may select it.
  # @return [void]
  def new
    authorize! with: CollectionPolicy

    @new_collection_form = NewCollectionForm.new
    @cancel_path = register_cancel_path
    set_new_apo_options(form: @new_collection_form)
    preselect_apo(form: @new_collection_form)
  end

  # Renders the form for editing and depositing a collection.
  # @return [void]
  def edit
    authorize! @cocina_object, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @edit_collection_form = prefilled_edit_form
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

    @edit_collection_form = submitted_edit_form
    return redirect_stale if @edit_collection_form.stale?

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

  # An APO the user may not select is ignored, leaving the first option selected.
  # @param form [NewCollectionForm]
  # @return [void]
  def preselect_apo(form:)
    apo_druid = params[:apo_druid].presence
    form.apo_druid = apo_druid if form.selectable_apo_druids.include?(apo_druid)
  end

  # The APOs the user can edit, plus the collection's current APO so that a user who can edit the collection
  # but not its APO can keep it; these are both the options and what the form accepts.
  # @param form [EditCollectionForm]
  # @return [void]
  def set_edit_apo_options(form:)
    @apo_options = apo_options(current_apo_druid: @cocina_object.administrative.hasAdminPolicy)
    form.selectable_apo_druids = @apo_options.map(&:last)
  end

  def prefilled_edit_form
    super.tap { |form| set_edit_apo_options(form:) }
  end

  def submitted_edit_form
    super.tap { |form| set_edit_apo_options(form:) }
  end

  def set_edit_view
    @title = CocinaSupport.title(@cocina_object)
    @druid_token = generate_token(@druid)
  end
end
