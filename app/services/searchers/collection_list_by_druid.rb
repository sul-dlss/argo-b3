# frozen_string_literal: true

module Searchers
  # Searcher that returns the collections with the provided druids, for populating select options.
  class CollectionListByDruid
    include Search::Fields

    def self.call(...)
      new(...).call
    end

    # @param druids [Array<String>] prefixed druids
    # @param user_scope [Permissions::UserScope, nil] the permission scope of the requesting user.
    #   Omit for collections that are already selected, which must not be dropped when the user cannot see them.
    # @param apo_druid [String, nil] if provided, limits to the collections governed by this APO
    def initialize(druids:, user_scope: nil, apo_druid: nil)
      @druids = druids
      @user_scope = user_scope
      @apo_druid = apo_druid
    end

    # @return [Array<Array(String, String)>] list of [title, druid] pairs, in the order of the druids.
    #   Collections that are not found are omitted.
    def call
      return [] if druids.empty?

      titles = solr_docs.to_h { |doc| [doc[ID], doc[TITLE]] }
      druids.filter_map { |druid| [titles[druid], druid] if titles.key?(druid) }
    end

    private

    attr_reader :druids, :user_scope, :apo_druid

    def solr_docs
      Search::SolrService.post(request: solr_request)['response']['docs']
    end

    def solr_request
      {
        q: '*:*',
        fq: ["#{OBJECT_TYPES}:collection", id_filter, apo_filter, permission_filter].compact,
        fl: [ID, TITLE],
        rows: druids.size
      }
    end

    def id_filter
      values = druids.map { |druid| "\"#{RSolr.solr_escape(druid)}\"" }.join(' OR ')
      "#{ID}:(#{values})"
    end

    def apo_filter
      "#{APO_DRUID}:\"#{RSolr.solr_escape(apo_druid)}\"" if apo_druid
    end

    def permission_filter
      Search::PermissionFilter.call(user_scope:) if user_scope
    end
  end
end
