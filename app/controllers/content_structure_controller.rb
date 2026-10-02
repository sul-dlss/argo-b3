# frozen_string_literal: true

# Controller for editing the structure of a content
class ContentStructureController < ContentsApplicationController
  STRUCTURE_VALUE = 'structure'
  APPEND_VALUE = 'append'
  CSV_VALUE = 'csv'

  skip_verify_authorized only: %i[edit update csv]
  before_action :set_content_and_cocina_object

  def edit
    @structure_changed = params[:structure_changed] == 'true' # Triggers a reload of the files section.
    set_populator_selection
    @structural_csv_form = StructuralCsvForm.new

    render layout: false
  end

  def update
    return upload_csv if params[:commit] == CSV_VALUE

    populator = find_populator
    if params[:commit] == APPEND_VALUE
      populator.append(content: @content, cocina_object: @cocina_object)
      flash[:toast] = t('edit.contents.structure.toasts.append')
    else
      populator.structure(content: @content, cocina_object: @cocina_object)
      flash[:toast] = t('edit.contents.structure.toasts.structure')
    end

    redirect_to_edit_with_structure_changed
  end

  # Exports the current (possibly in-progress) structure, not necessarily what has been saved to SDR.
  def csv
    send_data StructuralCsv::Export.as_csv(content: @content),
              type: 'text/csv', filename: "#{DruidSupport.bare_druid_from(@content.druid)}_structural.csv"
  end

  private

  # The selected content type, which may not have been saved yet.
  def set_populator_selection
    @content_type = params[:content_type]
    @populator_selection = Contents::PopulatorSelector.call(content: @content, cocina_object: @cocina_object,
                                                            content_type: @content_type)
  end

  def redirect_to_edit_with_structure_changed
    redirect_to edit_content_structure_path(@content_token, structure_changed: true,
                                                            content_type: params[:content_type].presence)
  end

  # Replaces the structure with the uploaded CSV. Nothing is changed unless the CSV is entirely valid.
  def upload_csv
    @structural_csv_form = StructuralCsvForm.new(structural_csv_params)
    return render_csv_errors unless @structural_csv_form.valid?

    druid_errors = csv_druid_errors
    return render_csv_errors(druid_errors) if druid_errors.any?

    import_result = StructuralCsv::Import.call(rows: @structural_csv_form.numbered_rows, content: @content)
    return render_csv_errors(import_result.failure) if import_result.failure?

    flash[:toast] = t('edit.contents.structure.toasts.csv')
    redirect_to_edit_with_structure_changed
  end

  def structural_csv_params
    params.permit(structural_csv: StructuralCsvForm.permitted_params)[:structural_csv]
  end

  # Since the CSV is for this object only, every row must have its druid (rather than being grouped by druid, as by
  # the bulk action). The druids have already been prefixed by CsvUpload::Normalizer.
  # A missing druid column is reported by StructuralCsv::Import.
  # @return [Array<StructuralCsv::ValidationError>]
  def csv_druid_errors
    @structural_csv_form.numbered_rows.filter_map do |row_number, row|
      next unless row.headers.include?('druid')

      druid = row['druid'].to_s.strip
      next if druid == @content.druid

      reason = druid.empty? ? 'Missing druid' : "Druid #{druid} does not match this object"
      StructuralCsv::ValidationError.new(row_number, reason)
    end
  end

  # @param validation_errors [Array<StructuralCsv::ValidationError>]
  def render_csv_errors(validation_errors = [])
    @structural_csv_form.add_validation_errors(validation_errors)
    set_populator_selection
    render :edit, layout: false, status: :unprocessable_content
  end

  def find_populator
    Contents::PopulatorSelector::POPULATORS_BY_NAME.fetch(params[:populator]) do
      raise ActionController::BadRequest, "Unknown populator: #{params[:populator]}"
    end
  end

  def set_content_and_cocina_object
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content = Content.with_structural_associations.find(verified_content_id)
    @cocina_object = fetch_cocina_object(druid: @content.druid, lock: @content.lock)
  end

  def fetch_cocina_object(druid:, lock:)
    cocina_hash = fetch_cocina_hash(druid:, lock:)
    CocinaSupport.build_from_cocina_hash(cocina_hash)
  end
end
