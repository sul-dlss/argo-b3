# frozen_string_literal: true

# Controller for refreshing an item's or collection's description from its FOLIO record, then depositing or, for an
# item, saving as a draft.
class ObjectFolioRefreshesController < ApplicationController
  include ObjectUpdatePageConcern

  def new
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @folio_refresh_form = form_class.for_edit(@cocina_object, version_service:)
    # The FOLIO link may have changed since the object page was shown.
    return redirect_not_refreshable if @folio_refresh_form.catalog_record_id.blank?

    @folio_refresh_form.retrieve_title
    set_unsaved_content_changes
  end

  def create # rubocop:disable Metrics/AbcSize
    authorize! @cocina_object, to: :update?, with: ObjectPolicy
    return redirect_not_editable unless version_service.editable?

    @folio_refresh_form = submitted_form
    return redirect_content_busy if @folio_refresh_form.content_busy?
    return render_invalid unless @folio_refresh_form.valid?(validation_context)

    @folio_refresh_form.save!(user_name: current_user.sunetid, accession: deposit?)
    redirect_saved
  rescue FolioRefreshFormConcern::NotDepositedError => e
    redirect_to object_path(@druid),
                flash: { danger: t('edit.object_folio_refreshes.errors.not_deposited', message: e.message) }
  rescue Sdr::FolioRefreshService::Error => e
    render_save_failed(e)
  end

  private

  # The "Refresh from FOLIO" button is shown only for items and collections.
  def form_class
    @cocina_object.collection? ? CollectionFolioRefreshForm : ItemFolioRefreshForm
  end

  # The errors of the content (e.g., not valid for the content type).
  def errors_without_field
    @folio_refresh_form.errors.messages_for(:content)
  end

  def redirect_not_refreshable
    redirect_to object_path(@druid), flash: { warning: t('edit.object_folio_refreshes.warnings.not_refreshable') }
  end
end
