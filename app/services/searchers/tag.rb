# frozen_string_literal: true

module Searchers
  # Searcher for tags (including project tags)
  class Tag
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param search_form [SearchForm]
    # @param field [String]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(search_form:, field:, user_scope:)
      @search_form = search_form
      @field = field
      @user_scope = user_scope
    end

    # @return [SearchResults::FacetValues] search results
    def call
      SearchResults::FacetValues.new(solr_response:, field:)
    end

    private

    attr_reader :search_form, :field, :user_scope

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      # This is a very imperfect way of querying for tags.
      {
        q: '*:*',
        fq: [Search::PermissionFilter.call(user_scope:)].compact,
        rows: 0,
        facet: true,
        'facet.field': field,
        'facet.matches': matches_regex,
        'facet.limit': 10_000,
        debugQuery: search_form.debug
      }
    end

    def matches_regex
      terms = search_form.query.split(/\s+/)
      joined_terms = terms.map { |term| Regexp.escape(term) }.join('|')
      "(?i)(.*(#{joined_terms}).*){#{terms.size}}"
    end
  end
end
