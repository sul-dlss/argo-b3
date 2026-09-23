# frozen_string_literal: true

module Searchers
  # Searcher that returns the collections the user can see with titles matching a query,
  # for populating select options.
  class CollectionList
    include Search::Fields

    LIMIT = 25

    QUERY_FIELDS = %w[
      main_title_text_anchored_im^100
      main_title_text_unstemmed_im^50
      full_title_unstemmed_im^10
      additional_titles_unstemmed_im^5
    ].freeze

    def self.call(...)
      new(...).call
    end

    # @param query [String] words from a title (the last may be partial)
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @param apo_druid [String, nil] if provided, limits to the collections governed by this APO
    def initialize(query:, user_scope:, apo_druid: nil)
      @query = query
      @user_scope = user_scope
      @apo_druid = apo_druid
    end

    # @return [Array<Array(String, String)>] list of [title, druid] pairs, in relevance order
    def call
      solr_docs.map { |doc| [doc[TITLE], doc[ID]] }
    end

    private

    attr_reader :query, :user_scope, :apo_druid

    def solr_docs
      Search::SolrService.post(request: solr_request)['response']['docs']
    end

    def solr_request
      {
        q: solr_query,
        defType: 'edismax',
        qf: QUERY_FIELDS.join(' '),
        mm: '100%', # every word in the query must match
        fq: ["#{OBJECT_TYPES}:collection", apo_filter, Search::PermissionFilter.call(user_scope:)].compact,
        fl: [ID, TITLE],
        rows: LIMIT
      }
    end

    # The last word is treated as a prefix, since the user may not have finished typing it.
    def solr_query
      words = query.split.map { |word| RSolr.solr_escape(word) }
      words[-1] = "#{words.last}*"
      words.join(' ')
    end

    def apo_filter
      "#{APO_DRUID}:\"#{RSolr.solr_escape(apo_druid)}\"" if apo_druid
    end
  end
end
