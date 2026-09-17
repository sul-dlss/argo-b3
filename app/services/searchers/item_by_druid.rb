# frozen_string_literal: true

module Searchers
  # Searcher for items (DROs, collections, or APOs) matching a list of druids
  class ItemByDruid
    def self.call(...)
      new(...).call
    end

    # @param druids [Array<String>]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @param fields [Array<String>] fields to include in the results
    def initialize(druids:, user_scope:, fields: Item::FIELD_LIST)
      @druids = druids
      @user_scope = user_scope
      @fields = fields
    end

    # @return [SearchResults::Items] search results
    def call
      SearchResults::Items.new(solr_response:, per_page: druids.size)
    end

    private

    attr_reader :druids, :user_scope, :fields

    def solr_response
      Search::SolrService.post(request: solr_request)
    end

    def solr_request
      {
        fq: [solr_fq, Search::PermissionFilter.call(user_scope:)].compact,
        fl: fields,
        rows: druids.size
      }
    end

    def solr_fq
      values = druids.map { |druid| "\"#{druid}\"" }.join(' OR ')
      "#{Search::Fields::ID}:(#{values})"
    end
  end
end
