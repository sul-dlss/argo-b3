# frozen_string_literal: true

module Searchers
  # Searcher that returns the Admin Policy Objects (APOs) with the provided druids, for populating select options.
  class AdminPolicyListByDruid
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param druids [Array<String>] prefixed druids
    # @param user_scope [Permissions::UserScope, nil] the permission scope of the requesting user.
    #   Omit for APOs that are already selected, which must not be dropped when the user cannot see them.
    def initialize(druids:, user_scope: nil)
      @druids = druids
      @user_scope = user_scope
    end

    # @return [Array<Array(String, String)>] list of [title, druid] pairs, in the order of the druids.
    #   APOs that are not found are omitted.
    def call
      return [] if druids.empty?

      titles = solr_docs.to_h { |doc| [doc[ID], doc[TITLE]] }
      druids.filter_map { |druid| [titles[druid], druid] if titles.key?(druid) }
    end

    private

    attr_reader :druids, :user_scope

    def solr_docs
      Search::SolrService.post(request: solr_request)['response']['docs']
    end

    def solr_request
      {
        q: '*:*',
        fq: ["#{OBJECT_TYPES}:APO", id_filter, permission_filter].compact,
        fl: [ID, TITLE],
        rows: druids.size
      }
    end

    def id_filter
      values = druids.map { |druid| "\"#{RSolr.solr_escape(druid)}\"" }.join(' OR ')
      "#{ID}:(#{values})"
    end

    def permission_filter
      Search::PermissionFilter.call(user_scope:) if user_scope
    end
  end
end
