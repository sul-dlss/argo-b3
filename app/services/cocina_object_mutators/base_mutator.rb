# frozen_string_literal: true

module CocinaObjectMutators
  # Mapper for merging a cocina model with an existing cocina object.
  class BaseMutator
    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata]
    # @param cocina_model [CocinaModels::Dro, CocinaModels::Collection]
    def initialize(cocina_object:, cocina_model:)
      @cocina_object = cocina_object
      @cocina_model = cocina_model
    end

    def call
      new_cocina_props = build_new_cocina_props

      Cocina::Models.with_metadata(Cocina::Models.build(new_cocina_props), cocina_object.lock)
    end

    private

    attr_reader :cocina_object, :cocina_model

    def build_new_cocina_props # rubocop:disable Metrics/AbcSize
      Cocina::Models.without_metadata(cocina_object).to_h.tap do |new_cocina_props|
        new_cocina_props[:identification][:sourceId] = cocina_model.source_id
        new_cocina_props[:access][:useAndReproductionStatement] = cocina_model.use_and_reproduction_statement
        new_cocina_props[:access][:license] = cocina_model.license
        new_cocina_props[:access][:copyright] = cocina_model.copyright
        new_cocina_props[:identification][:catalogLinks] = build_catalog_links
      end
    end

    def build_catalog_links
      # symphony, previous symphony, and previous folio catalog links are retained as is.
      # If an existing folio catalog link is not in the new catalog links, it changed to a previous folio catalog link.
      # The new Folio catalog link is added, with refresh, partLabel, and sortKey if present.
      # The rest of the new Folio catalog links are added, with default refresh of false.
      build_catalog_links_from_model +
        build_existing_folio_catalog_links +
        existing_catalog_links_for('symphony').map(&:to_h) +
        existing_catalog_links_for('previous symphony').map(&:to_h) +
        existing_catalog_links_for('previous folio').map(&:to_h)
    end

    def build_catalog_links_from_model # rubocop:disable Metrics/AbcSize
      cocina_model.folio_catalog_links.map.with_index do |catalog_link, index|
        { catalog: 'folio', catalogRecordId: catalog_link.catalog_record_id, refresh: false }.tap do |link_hash|
          if index.zero?
            link_hash[:refresh] = cocina_model.catalog_link_refresh
            link_hash[:partLabel] = cocina_model.catalog_link_part_label
            link_hash[:sortKey] = cocina_model.catalog_link_sort_key
          end
        end.compact
      end
    end

    def build_existing_folio_catalog_links
      existing_catalog_links_for('folio').filter_map do |existing_link|
        next if cocina_model.find_folio_catalog_link(catalog_record_id: existing_link.catalogRecordId).present?

        {
          catalog: 'previous folio',
          catalogRecordId: existing_link.catalogRecordId,
          refresh: false
        }
      end
    end

    def existing_catalog_links_for(catalog)
      cocina_object.identification.catalogLinks.select { |link| link.catalog == catalog }
    end
  end
end
