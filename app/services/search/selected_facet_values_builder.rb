# frozen_string_literal: true

module Search
  # Builds a Solr JSON query facet that counts a facet's selected and excluded values,
  # so that they can be listed even when they are not among the facet's top values.
  # See SearchResults::FacetCounts.
  class SelectedFacetValuesBuilder
    def self.call(...)
      new(...).call
    end

    # @return [String] the key of the query facet in the JSON facet request and response
    def self.key(facet_config)
      "#{facet_config.facet_field}-selected"
    end

    # @param query [String] the query of a value's facet, as built by #value_facet
    # @return [String] the value
    def self.value_from(facet_config:, query:)
      query.delete_prefix(term_prefix(facet_config))
    end

    def self.term_prefix(facet_config)
      "{!term f=#{facet_config.field}}"
    end

    # @param facet_config [Search::Facets::Config]
    # @param search_form [SearchForm]
    def initialize(facet_config:, search_form:)
      @facet_config = facet_config
      @search_form = search_form
    end

    # @return [Hash] the query facet keyed by .key, or empty if no values are selected
    def call
      return {} if values.empty?

      value_facets = values.each_with_index.to_h { |value, index| [index.to_s, value_facet(value)] }
      facet = { type: 'query', q: '*:*', facet: value_facets }
      # The counts ignore the facet's own filters, as the facet's top values do (see FacetsBuilder).
      facet[:domain] = { excludeTags: [facet_config.field] } if exclude_own_filters?
      { self.class.key(facet_config) => facet }
    end

    private

    attr_reader :facet_config, :search_form

    def exclude_own_filters?
      FacetsBuilder.exclude?(facet_config:, search_form:)
    end

    def values
      return [] if facet_config.dynamic_facet.present? || facet_config.hierarchical?

      form_fields = [facet_config.form_field, facet_config.exclude_form_field].compact
      form_fields.flat_map { |form_field| search_form.send(form_field) }
                 .uniq
                 .reject { |value| Search::Facets.missing_value?(value) }
    end

    def value_facet(value)
      facet = { type: 'query', q: "#{self.class.term_prefix(facet_config)}#{value}" }
      return facet unless facet_config.composite_facet_field

      # The composite values hold the labels; other values of a multivalued field are ignored.
      facet.merge(facet: { labels: { type: 'terms', field: facet_config.composite_facet_field, limit: -1 } })
    end
  end
end
