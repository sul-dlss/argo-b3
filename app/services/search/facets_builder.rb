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
          facet_hash[facet_config.facet_field] = facet_json_for(facet_config)
        end
      end
    end

    private

    attr_reader :facet_configs

    def facet_json_for(facet_config)
      exclude = facet_config.exclude || facet_config.exclude_form_field.present?
      Search::FacetBuilder.call(field: facet_config.facet_field, tag: facet_config.field, exclude:,
                                **facet_config.to_h.slice(:limit, :alpha_sort))
    end
  end
end
