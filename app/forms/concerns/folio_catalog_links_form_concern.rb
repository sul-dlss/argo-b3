# frozen_string_literal: true

# Concern for forms that edit an object's Folio catalog links: catalog_record_id edits the first link, which
# carries refresh, part label and sort key; additional_folio_catalog_links edit the rest.
# Requires CatalogRecordIdFormConcern and CatalogRecordIdExistsFormConcern.
module FolioCatalogLinksFormConcern
  extend ActiveSupport::Concern

  included do
    has_many :additional_folio_catalog_links, class_name: 'AdditionalCatalogRecordIdForm'
    before_validation :sync_folio_catalog_links
    validate :catalog_record_id_present_with_catalog_link_fields

    # Defined here to override the writer defined by has_many.
    # Replaces rather than appends, since removed rows are only removed in the browser.
    def additional_folio_catalog_links_attributes=(attributes)
      additional_folio_catalog_links.clear
      assign_nested_attributes_for_collection_association(:additional_folio_catalog_links, attributes)
    end
  end

  private

  # A changed catalog record id replaces the first Folio catalog link; a blank one removes it.
  # Blank and duplicate catalog record ids are dropped.
  def sync_folio_catalog_links
    existing_catalog_record_ids = existing_folio_catalog_record_ids
    [self, *additional_folio_catalog_links].each { |form| form.linked_catalog_record_ids = existing_catalog_record_ids }
    catalog_record_ids = [catalog_record_id, *additional_catalog_record_ids].compact_blank.uniq
    self.folio_catalog_links = catalog_record_ids.map do |id|
      CocinaModels::FolioCatalogLink.new(catalog_record_id: id)
    end
  end

  def additional_catalog_record_ids
    additional_folio_catalog_links.map(&:catalog_record_id)
  end

  # Additional catalog record ids, part label, and sort key would otherwise be dropped without a catalog record id.
  def catalog_record_id_present_with_catalog_link_fields
    return if catalog_record_id.present?
    return if [*additional_catalog_record_ids, catalog_link_part_label, catalog_link_sort_key].compact_blank.empty?

    errors.add(:catalog_record_id, I18n.t('edit.items.fields.catalog_record_id.errors.blank'))
  end

  def model_attrs_for(cocina_object)
    super.then do |attrs|
      first_link, *additional_links = attrs[:folio_catalog_links_attributes]
      attrs.merge(catalog_record_id: first_link&.dig(:catalog_record_id),
                  additional_folio_catalog_links_attributes: additional_links)
    end
  end
end
