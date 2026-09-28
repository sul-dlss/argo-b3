# frozen_string_literal: true

module Search
  # Resolves the display labels (e.g., titles) for the ids (e.g., druids) currently selected on composite facets
  # (APOs, Collections, Licenses), for use in the current-filter pills. Composite facets carry both
  # the id and the label together, but a *selected* filter value is just a bare id (from the
  # URL/SearchForm), so there's nowhere to get the human label from -- this looks the label back up.
  class CompositeFacetLabels
    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    def initialize(search_form:)
      @search_form = search_form
    end

    # @return [Hash<String, String>] id => label, for every currently selected composite facet value
    def call
      composite_facet_configs.each_with_object({}) do |facet_config, labels|
        labels.merge!(labels_for(facet_config))
      end
    end

    private

    attr_reader :search_form

    def composite_facet_configs
      Search::Facets.constants.filter_map do |const_name|
        config = Search::Facets.const_get(const_name)
        config if config.is_a?(Search::Facets::Config) && config.composite_facet_field.present?
      end
    end

    def labels_for(facet_config)
      ids = search_form.send(facet_config.form_field)
      return {} if ids.blank?

      facet_buckets(facet_config:, ids:).each_with_object({}) do |bucket, labels|
        id, label = Search::CompositeFacetValue.parse(bucket['val'])
        labels[id] = label
      end
    end

    def facet_buckets(facet_config:, ids:)
      Search::SolrService.post(request: solr_request(facet_config:, ids:))
                         .dig('facets', facet_config.composite_facet_field, 'buckets') || []
    end

    def solr_request(facet_config:, ids:)
      values = ids.map { |id| "\"#{id}\"" }.join(' OR ')
      {
        q: '*:*',
        fq: "#{facet_config.field}:(#{values})",
        'json.facet': {
          facet_config.composite_facet_field => Search::FacetBuilder.call(field: facet_config.composite_facet_field,
                                                                          limit: ids.size)
        }.to_json,
        rows: 0
      }
    end
  end
end
