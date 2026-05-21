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
    def call # rubocop:disable Metrics/AbcSize
      {
        source_id: cocina_object.identification.sourceId,
        use_and_reproduction_statement: cocina_object.access.useAndReproductionStatement,
        license: cocina_object.access.license,
        copyright: cocina_object.access.copyright,
        folio_catalog_links_attributes: folio_catalog_link_attributes,
        catalog_link_refresh: refreshing_folio_catalog_link&.refresh,
        catalog_link_part_label: refreshing_folio_catalog_link&.partLabel,
        catalog_link_sort_key: refreshing_folio_catalog_link&.sortKey
      }.compact
    end

    private

    attr_reader :cocina_object

    def folio_catalog_links
      @folio_catalog_links ||= Array(cocina_object.identification&.catalogLinks).select do |link|
        link.catalog == 'folio'
      end
    end

    def refreshing_folio_catalog_link
      # There should only be one.
      @refreshing_folio_catalog_link ||= folio_catalog_links.find(&:refresh)
    end

    def folio_catalog_link_attributes
      # Refreshing catalog link goes first if there is one.
      ordered_links = [refreshing_folio_catalog_link].compact + (folio_catalog_links - [refreshing_folio_catalog_link])
      ordered_links.map do |link|
        { catalog_record_id: link.catalogRecordId }
      end
    end
  end
end
