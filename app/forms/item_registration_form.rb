# frozen_string_literal: true

# Form object for registering a single item as part of multiple item registration (DROs)
class ItemRegistrationForm < ApplicationForm
  include PermittedParamsConcern
  include PrevalidationConcern
  include CocinaModels::SourceIdConcern
  include CocinaModels::BarcodeConcern
  include CocinaModels::CatalogRecordIdConcern
  include TitleFormConcern

  validate :title_present_unless_catalog_record_id
  validate :catalog_record_id_exists

  def empty?
    model_attributes.values.all?(&:blank?)
  end

  private

  def title_present_unless_catalog_record_id
    return if title.present? || catalog_record_id.present?

    errors.add(:title, I18n.t('edit.items.fields.title.validations.required'))
  end

  def catalog_record_id_exists
    return if catalog_record_id.blank? || errors[:catalog_record_id].present?

    # allow_catalog_errors is true to prevent Folio from interfering with registration
    return if CatalogRepository.exists?(catalog_record_id:, allow_catalog_errors: true)

    errors.add(:catalog_record_id, I18n.t('edit.items.fields.catalog_record_id.validations.not_found'))
  end
end
