# frozen_string_literal: true

module Search
  # Service for building dynamic facets for a search
  class DynamicFacetBuilder
    def self.call(...)
      new(...).call
    end

    # @param form_field [Symbol] the form field for the dynamic facet
    # @param dynamic_facet [Hash{Symbol => String}] the dynamic facet definition (key to Solr query)
    def initialize(form_field:, dynamic_facet:)
      @form_field = form_field
      @dynamic_facet = dynamic_facet
    end

    def call
      dynamic_facet.each_with_object({}) do |(key, query), hash|
        hash["#{form_field}-#{key}"] = { type: 'query', q: query }
      end
    end

    private

    attr_reader :form_field, :dynamic_facet
  end
end
