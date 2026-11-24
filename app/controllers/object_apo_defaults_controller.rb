# frozen_string_literal: true

# Controller for applying the governing APO's access and rights defaults to an item or collection, then depositing
# or, for an item, saving as a draft.
class ObjectApoDefaultsController < ApplicationController
  include ObjectUpdatePageConcern

  def new
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @apo_defaults_form = form_class.for_edit(@cocina_object, version_service:)
    set_unsaved_content_changes
  end

  def create
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @apo_defaults_form = submitted_form
    return redirect_content_busy if @apo_defaults_form.content_busy?
    return render_invalid unless @apo_defaults_form.valid?(validation_context)

    @apo_defaults_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_saved
  rescue Sdr::Repository::Error => e
    render_save_failed(e)
  end

  private

  # The "Apply APO defaults" button is shown only for items and collections.
  def form_class
    @cocina_object.collection? ? CollectionApoDefaultsForm : ItemApoDefaultsForm
  end

  # The errors of the content (e.g., not valid for the content type) and of the access built from the APO defaults.
  def errors_without_field
    errors = @apo_defaults_form.errors
    errors.messages_for(:content) + errors.full_messages_for(:access) + errors.full_messages_for(:embargo_access)
  end
end
