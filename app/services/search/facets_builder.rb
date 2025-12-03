# frozen_string_literal: true

module Search
  # Builds facet parameters for Solr JSON Facet API from facet configs
  class FacetsBuilder
    def self.call(...)
      new(...).call
    end

    def initialize(facet_configs:)
      @facet_configs = facet_configs
    end

    def call
      facet_configs.each_with_object({}) do |facet_config, facet_hash|
        if facet_config.dynamic_facet.present?
          facet_hash.merge!(Search::DynamicFacetBuilder.call(**facet_config.to_h.slice(:form_field, :dynamic_facet)))
        else
          facet_hash[facet_config.field] =
            Search::FacetBuilder.call(**facet_config.to_h.slice(:field, :limit, :alpha_sort, :exclude))
        end
      end
    end

    private

    attr_reader :facet_configs
  end
end
