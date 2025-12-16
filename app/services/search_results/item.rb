# frozen_string_literal: true

module SearchResults
  # Search results for an item (DROs, collections, or APOs)
  class Item
    def initialize(solr_doc:, index:)
      @solr_doc = solr_doc
      @index = index
    end

    def bare_druid
      DruidSupport.bare_druid_from(druid)
    end

    def druid
      solr_doc[Search::Fields::ID]
    end

    def apo_druid
      solr_doc[Search::Fields::APO_DRUID]&.first
    end

    def apo_title
      solr_doc[Search::Fields::APO_TITLE]&.first
    end

    # Derive a getter method from the constant for a field in Search::Fields.
    # For example, bare_druid() is handled equivalent to defining:
    # def bare_druid
    #   solr_doc[Search::Fields::BARE_DRUID]
    # end
    def method_missing(method_name, *, &)
      return super unless respond_to_missing?(method_name)

      field = Search::Fields.const_get(method_name_to_const_name(method_name))
      solr_doc[field]
    end

    def respond_to_missing?(method_name, include_private = false)
      Search::Fields.const_defined?(method_name_to_const_name(method_name)) || super
    end

    attr_reader :solr_doc, :index

    private

    def method_name_to_const_name(method_name)
      method_name.to_s.upcase
    end
  end
end
