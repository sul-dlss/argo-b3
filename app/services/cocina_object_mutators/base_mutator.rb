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
      end
    end
  end
end
