# frozen_string_literal: true

module Searchers
  # Searcher for the titles of objects (DROs, collections, or APOs), for display; it skips permission checks.
  class TitlesByDruid
    def self.call(...)
      new(...).call
    end

    # @param druids [Array<String>] prefixed druids; Solr's maxBooleanClauses limits how many
    def initialize(druids:)
      @druids = druids.uniq
    end

    # @return [Hash<String, String>] the title of each druid, or its bare druid if the object is not in Solr
    def call
      return {} if druids.empty?

      titles = ItemByDruid.call(druids:, user_scope: nil, fields: [Search::Fields::ID, Search::Fields::TITLE])
                          .to_h { |item| [item.druid, item.title] }
      druids.index_with { |druid| titles[druid] || DruidSupport.bare_druid_from(druid) }
    end

    private

    attr_reader :druids
  end
end
