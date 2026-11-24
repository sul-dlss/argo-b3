# frozen_string_literal: true

module Search
  # Builds facet parameters for Solr JSON Facet API from facet configs
  class FacetsBuilder
    def self.call(...)
      new(...).call
    end

    # True if the facet's counts ignore the facet's own filters (see ItemQueryBuilder#facet_filter_query).
    # @param facet_config [Search::Facets::Config]
    # @param search_form [SearchForm] the search, which may choose the facet's operator
    def self.exclude?(facet_config:, search_form:)
      search_form.operator_for(facet_config) == :or || facet_config.exclude_form_field.present?
    end

    # @param facet_configs [Array<Search::Facets::Config>]
    # @param search_form [SearchForm] the search, whose selected values are counted for each facet
    def initialize(facet_configs:, search_form:)
      @facet_configs = facet_configs
      @search_form = search_form
    end

    def call
      facet_configs.each_with_object({}) do |facet_config, facet_hash|
        if facet_config.dynamic_facet.present?
          facet_hash.merge!(Search::DynamicFacetBuilder.call(**facet_config.to_h.slice(:form_field, :dynamic_facet)))
        else
          facet_hash[facet_config.facet_field] = facet_json_for(facet_config)
          facet_hash.merge!(Search::SelectedFacetValuesBuilder.call(facet_config:, search_form:))
        end
      end
    end

    private

    attr_reader :facet_configs, :search_form

    def facet_json_for(facet_config)
      Search::FacetBuilder.call(field: facet_config.facet_field, tag: facet_config.field,
                                exclude: self.class.exclude?(facet_config:, search_form:),
                                **facet_config.to_h.slice(:limit, :alpha_sort, :missing_value))
    end
  end
end
