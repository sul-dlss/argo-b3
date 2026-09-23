# frozen_string_literal: true

module Searchers
  # Searcher that returns the list of Admin Policy Objects (APOs), for populating select options.
  class AdminPolicyList
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    def initialize(user_scope:)
      @user_scope = user_scope
    end

    # @return [Array<Array(String, String)>] list of [title, druid] pairs, sorted by title
    def call
      # Sorting here because title field is not indexed in Solr for sorting.
      solr_response['response']['docs'].map { |doc| [doc[TITLE], doc[ID]] }.sort_by { |title, _druid| title.downcase }
    end

    private

    attr_reader :user_scope

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      {
        q: '*:*',
        fq: ["#{OBJECT_TYPES}:APO", Search::PermissionFilter.call(user_scope:)].compact,
        fl: [ID, TITLE],
        rows: 10_000
      }
    end
  end
end
