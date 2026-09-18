# frozen_string_literal: true

module Search
  # Builds Solr filter query fragments for exact-value matches.
  module SolrFilter
    # @param values [Array<String>]
    # @return [String] Solr-escaped, quoted values joined for use inside a field:(...) filter
    def self.quoted_values(values)
      values.map { |value| %("#{RSolr.solr_escape(value)}") }.join(' OR ')
    end
  end
end
