# frozen_string_literal: true

module Search
  # Builds the filter query for the user-supplied year range of a facet of years (e.g., the publication year).
  # Years are indexed in a Solr string field, so a Solr range query would compare them lexicographically
  # (e.g., 201 falls between 2000 and 2020, and negative years are out of order). Instead, the query lists
  # each year in the range. The terms parser is not subject to the boolean clause limit, so it handles the full
  # range of years.
  class YearRangeQuery
    def self.call(...)
      new(...).call
    end

    # @param facet_config [Search::Facets::Config] a facet config with year_from_form_field and year_to_form_field
    # @param search_form [SearchForm] a search form whose year range form fields are YearType attributes
    def initialize(facet_config:, search_form:)
      @facet_config = facet_config
      @from = search_form.public_send(facet_config.year_from_form_field)
      @to = search_form.public_send(facet_config.year_to_form_field)
    end

    # @return [String, nil] the filter query or nil if neither a from nor a to year is provided
    def call
      return if from.nil? && to.nil?

      "{!terms f=#{facet_config.field}}#{years.join(',')}"
    end

    private

    attr_reader :facet_config, :from, :to

    # An open-ended range extends to the earliest or latest year. Since the years are limited (see YearType),
    # the number of terms is bounded.
    def years
      first_year, last_year = [from || YearType::MIN, to || YearType::MAX].minmax
      (first_year..last_year).to_a
    end
  end
end
