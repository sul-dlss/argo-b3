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
        copyright: cocina_object.access.copyright
      }.compact
    end

    private

    attr_reader :cocina_object
  end
end
