# frozen_string_literal: true

# Concern for forms that check that a new catalog record id exists in FOLIO.
# Requires CatalogRecordIdFormConcern.
module CatalogRecordIdExistsFormConcern
  extend ActiveSupport::Concern

  included do
    validate :catalog_record_id_exists

    # The catalog record ids already linked to the object, which are not checked against FOLIO again.
    # Not an attribute, so that it is not a param.
    attr_writer :linked_catalog_record_ids
  end

  private

  def linked_catalog_record_ids
    @linked_catalog_record_ids || []
  end

  def catalog_record_id_exists
    return if catalog_record_id.blank? || errors[:catalog_record_id].present?
    return if linked_catalog_record_ids.include?(catalog_record_id)
    return if catalog_record_id_exists?

    errors.add(:catalog_record_id, I18n.t('edit.items.fields.catalog_record_id.validations.not_found'))
  end

  # Memoized, since the form is validated both before and when saving.
  # allow_catalog_errors is true to prevent Folio from interfering with editing.
  def catalog_record_id_exists?
    @catalog_record_id_exists ||= {}
    @catalog_record_id_exists.fetch(catalog_record_id) do
      @catalog_record_id_exists[catalog_record_id] =
        CatalogRepository.exists?(catalog_record_id:, allow_catalog_errors: true)
    end
  end
end
