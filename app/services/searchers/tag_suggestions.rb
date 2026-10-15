# frozen_string_literal: true

module Searchers
  # Searcher for suggesting existing tags of a type (other, project, or ticket) while a user is entering a tag.
  # Project and ticket suggestions are returned without their prefixes (e.g., "Project : ").
  class TagSuggestions
    include Search::Fields

    LIMIT = 25

    FIELDS = {
      'other' => OTHER_TAGS_EXPLODED,
      'project' => PROJECTS,
      'ticket' => TICKETS
    }.freeze

    TAG_TYPES = FIELDS.keys.freeze

    def self.call(...)
      new(...).call
    end

    # @param query [String] the text entered so far, matched case-insensitively anywhere in the tag
    # @param tag_type [String] one of TAG_TYPES
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(query:, tag_type:, user_scope:)
      raise ArgumentError, "Unknown tag type: #{tag_type}" unless TAG_TYPES.include?(tag_type)

      @query = query
      @tag_type = tag_type
      @user_scope = user_scope
    end

    # @return [SearchResults::FacetValues] matching tags
    def call
      SearchResults::FacetValues.new(solr_response:, field:)
    end

    private

    attr_reader :query, :tag_type, :user_scope

    def field
      FIELDS.fetch(tag_type)
    end

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      {
        q: '*:*',
        fq: [Search::PermissionFilter.call(user_scope:)].compact,
        rows: 0,
        facet: true,
        'facet.field': field,
        'facet.matches': matches_regex,
        'facet.mincount': 1,
        'facet.limit': LIMIT,
        'facet.sort': 'index'
      }
    end

    # Solr matches the regex against the whole facet value.
    def matches_regex
      "(?i)#{other_tag_lookaheads if tag_type == 'other'}.*#{Regexp.escape(query.strip)}.*"
    end

    # The exploded other tags field includes every ancestor of a tag (e.g., "A" for "A : B") and
    # Registered By tags. Only suggest values that are valid other tags (see OtherTagForm::VALID_TAG_PATTERN)
    # and that are not Registered By tags.
    def other_tag_lookaheads
      '(?!registered by : )(?=.* : )'
    end
  end
end
