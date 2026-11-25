# frozen_string_literal: true

# Controller for extracting text (OCR or speech to text) from an item
class ItemTextExtractionsController < ApplicationController
  include ObjectUpdatePageConcern

  def new
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @item_text_extraction_form = form_class.for_edit(@cocina_object, version_service:)
    set_unsaved_content_changes
  end

  def create
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @item_text_extraction_form = submitted_form
    return redirect_content_busy if @item_text_extraction_form.content_busy?
    return render_invalid unless @item_text_extraction_form.valid?(validation_context)

    @item_text_extraction_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_saved
  rescue Sdr::Repository::Error => e
    render_save_failed(e)
  end

  private

  def form_class
    ItemTextExtractionForm
  end

  # The errors of the content (e.g., not valid for the content type).
  def errors_without_field
    @item_text_extraction_form.errors.messages_for(:content)
  end
end
