# frozen_string_literal: true

# Controller for downloading the stored cocina of a version of an object.
class ObjectVersionsController < ApplicationController
  include TokenConcern

  # As with the ObjectsController show endpoints, authorization happens on ObjectsController#show.
  # The druid is signed by that action and verified here, which acts as authorization.
  skip_verify_authorized only: %i[cocina structural_csv descriptive_csv]
  self.token_purpose = 'show'

  before_action :set_cocina_object

  def cocina
    cocina_hash = invalid_cocina? ? @cocina_object.cocina_hash : without_metadata.to_h
    # Blanks are removed as for the Cocina JSON tab.
    render json: CocinaDisplay::Utils.deep_compact_blank(cocina_hash, preserve_keys: [:label])
  end

  def structural_csv
    return invalid_cocina_redirect(t('object_versions.errors.invalid_cocina_structural')) if invalid_cocina?

    # Built in memory, since the version's cocina has the object's current lock.
    send_data StructuralCsv::Export.as_csv(content: Contents::Builder.build(cocina_object: @cocina_object)),
              type: 'text/csv', filename: "#{filename_prefix}_structural.csv"
  end

  def descriptive_csv
    return invalid_cocina_redirect(t('object_versions.errors.invalid_cocina_descriptive')) if invalid_cocina?

    description = DescriptiveCsv::Export.export(source_id: @cocina_object.identification.sourceId,
                                                description: @cocina_object.description)
    send_data DescriptiveCsv::Export.as_csv(descriptions: { druid => description }),
              type: 'text/csv', filename: "#{filename_prefix}_description.csv"
  end

  private

  def set_cocina_object
    @cocina_object = Sdr::Repository.find_version(druid:, version: params[:version])
  end

  def druid
    @druid ||= verify_token(params[:object_druid])
  end

  def invalid_cocina?
    @cocina_object.is_a?(Sdr::Repository::InvalidCocina)
  end

  def without_metadata
    Cocina::Models.without_metadata(@cocina_object)
  end

  def invalid_cocina_redirect(message)
    flash[:danger] = message
    redirect_to object_path(druid:)
  end

  def filename_prefix
    "#{DruidSupport.bare_druid_from(druid)}_v#{params[:version]}"
  end
end
