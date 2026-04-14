# frozen_string_literal: true

module SearchResults
  # Search results for an item (DROs, collections, or APOs)
  class Item
    def initialize(solr_doc:, index: nil)
      @solr_doc = solr_doc
      @index = index
    end

    def bare_druid
      DruidSupport.bare_druid_from(druid)
    end

    def druid
      solr_doc[Search::Fields::ID]
    end

    # Derive a getter method from the constant for a field in Search::Fields.
    # For example, bare_druid() is handled equivalent to defining:
    # def bare_druid
    #   solr_doc[Search::Fields::BARE_DRUID]
    # end
    def method_missing(method_name, *, &)
      field = if method_defined?(method_name)
                Search::Fields.const_get(method_name_to_const_name(method_name))
              elsif method_defined?(method_name, pluralize: true)
                Search::Fields.const_get(method_name_to_const_name(method_name, pluralize: true))
              else
                return super
              end
      value = solr_doc[field]
      SCALAR_FIELDS.include?(field) ? Array(value)&.first : value
    end

    def respond_to_missing?(method_name, include_private = false)
      method_defined?(method_name) || method_defined?(method_name, pluralize: true) || super
    end

    attr_reader :solr_doc, :index

    private

    def method_defined?(method_name, pluralize: false)
      Search::Fields.const_defined?(method_name_to_const_name(method_name, pluralize:))
    end

    # Fields to return the first value for instead of an array.
    # This is sloppiness in the indexing -- they should not have been arrays.
    SCALAR_FIELDS = [
      Search::Fields::OBJECT_TYPES,
      Search::Fields::APO_DRUID,
      Search::Fields::APO_TITLE
    ].freeze
    private_constant :SCALAR_FIELDS

    def method_name_to_const_name(method_name, pluralize: false)
      method_name = method_name.to_s
      method_name = method_name.pluralize if pluralize
      method_name.upcase
    end
  end
end
