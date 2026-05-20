# frozen_string_literal: true

module CocinaModelMappers
  # Base mapper for mapping a cocina object to a hash of attributes for a cocina model.
  class BaseMapper
    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata]
    def initialize(cocina_object:)
      @cocina_object = cocina_object
    end

    # @return [Hash] the mapped attributes
    def call
      {
        source_id: cocina_object.identification.sourceId,
        use_and_reproduction_statement: cocina_object.access.useAndReproductionStatement,
        license: cocina_object.access.license,
        copyright: cocina_object.access.copyright,
        symphony_catalog_links_attributes: symphony_catalog_link_attributes_for('symphony'),
        previous_symphony_catalog_links_attributes: symphony_catalog_link_attributes_for('previous symphony'),
        folio_catalog_links_attributes: folio_catalog_link_attributes_for('folio'),
        previous_folio_catalog_links_attributes: folio_catalog_link_attributes_for('previous folio')

      }.compact
    end

    private

    attr_reader :cocina_object

    def symphony_catalog_link_attributes_for(catalog)
      links_for(catalog).map do |catalog_link|
        {
          catalog_record_id: catalog_link.catalogRecordId,
          refresh: catalog_link.refresh
        }
      end
    end

    def folio_catalog_link_attributes_for(catalog)
      links_for(catalog).map do |catalog_link|
        {
          catalog_record_id: catalog_link.catalogRecordId,
          refresh: catalog_link.refresh,
          part_label: catalog_link.partLabel,
          sort_key: catalog_link.sortKey
        }
      end
    end

    def links_for(catalog)
      (cocina_object.identification&.catalogLinks || []).select { |catalog_link| catalog_link.catalog == catalog }
    end
  end
end
