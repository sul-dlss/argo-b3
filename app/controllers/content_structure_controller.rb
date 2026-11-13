# frozen_string_literal: true

# Controller for the structure of a content: deleting it, exporting it, and validating it.
# Structuring files and uploading a structural CSV are steps of managing files (see ContentsController).
class ContentStructureController < ContentsApplicationController
  skip_verify_authorized only: %i[destroy csv validation]
  before_action :set_content

  # Deletes all of the files and resources, then reloads the page on the add and edit files step.
  def destroy
    # Deleting is disabled while busy (e.g., discovering may be adding files), so this is from a stale page.
    if @content.busy?
      return redirect_to edit_content_path(@content.druid),
                         flash: { warning: t('edit.contents.structure.warnings.busy') }
    end

    ActiveRecord::Base.transaction do
      ContentFileSet.where(content: @content).destroy_all
      Contents::ContentFileBinaryDestroyer.call(content_file_binaries: ContentFileBinary.where(content: @content).to_a)
      @content.update!(step: :files)
    end
    redirect_to edit_content_path(@content.druid), flash: { toast: t('edit.contents.structure.toasts.delete_all') }
  end

  # Exports the current (possibly in-progress) structure, not necessarily what has been saved to SDR.
  def csv
    send_data StructuralCsv::Export.as_csv(content: @content),
              type: 'text/csv', filename: "#{DruidSupport.bare_druid_from(@content.druid)}_structural.csv"
  end

  # Validates the current (possibly in-progress) structure against the selected content type.
  # This is a separate frame so that it can be reloaded when a resource changes without reloading the structure,
  # which may contain resources that are being edited.
  def validation
    saved_cocina_object = fetch_cocina_object(druid: @content.druid, lock: @content.lock)
    @content_validation_result = Contents::Validator.call(
      content: @content,
      cocina_object: @content.with_selected_access(saved_cocina_object),
      content_type: @content.selected_content_type(saved_cocina_object),
      saved_access: saved_cocina_object.access
    )

    render layout: false
  end

  private

  def set_content
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content = Content.with_structural_associations.find(verified_content_id)
  end

  def fetch_cocina_object(druid:, lock:)
    cocina_hash = fetch_cocina_hash(druid:, lock:)
    CocinaSupport.build_from_cocina_hash(cocina_hash)
  end
end
