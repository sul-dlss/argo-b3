# frozen_string_literal: true

# Controller for registering and depositing collections
class CollectionsController < ApplicationController
  # Renders the form for registering and depositing a collection.
  # @return [void]
  def new
    authorize! with: CollectionPolicy

    @new_collection_form = NewCollectionForm.new
    @cancel_path = (request.referer if request.referer.present? && request.referer.exclude?(new_collection_path)) ||
                   root_path
    set_apo_options(form: @new_collection_form)
  end

  # Registers and deposits a collection, or re-renders the form if it is invalid.
  # @return [void]
  def create
    @new_collection_form = NewCollectionForm.new(new_collection_form_params)
    # to_s, since a nil record would be replaced by ActionPolicy's implicit target.
    authorize! @new_collection_form.apo_druid.to_s, with: CollectionPolicy

    set_apo_options(form: @new_collection_form)
    return render_invalid unless @new_collection_form.valid?

    @new_collection_form.create!(user_name: current_user.sunetid)
    redirect_to object_path(@new_collection_form.druid), flash: { toast: t('edit.collections.new.toasts.register') }
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
  def set_apo_options(form:)
    @apo_options = Searchers::AdminPolicyList.call(user_scope: current_user_scope, editable: true)
    form.selectable_apo_druids = @apo_options.map(&:last)
  end
end
