# frozen_string_literal: true

module Search
  # Constants for sort option configurations
  module SortOptions
    def self.find_config_by_sort_field(sort_field)
      Search::SortOptions.constants.each do |const_name|
        config = Search::SortOptions.const_get(const_name)
        return config if config.is_a?(Config) && const_name.to_s.downcase == sort_field
      end
      nil
    end

    # Relevance (with its id tiebreaker) is the implicit default sort: without it, ties would be
    # broken by Solr's internal doc order, which is not guaranteed stable across separate requests
    # and would make search result navigation (previous/next) unreliable.
    # @return [String] the Solr sort value for the given sort field, defaulting to relevance
    def self.sort_value_for(sort_field)
      (find_config_by_sort_field(sort_field) || RELEVANCE).sort_value
    end

    Config = Struct.new(:label, :sort_value)

    # Secondary sorts on druid (id) keep paging stable when objects share the primary sorted attribute.
    RELEVANCE = Config.new(label: 'Relevance', sort_value: 'score desc, id asc')
    # Use exists(FIELD) desc first returns true/false on that field sorted true first,
    # ensuring the next sort on FIELD applies only to that those with values first, then others next
    LAST_DEPOSITED_DATE_ASC = Config.new(label: 'Last deposited date (ascending)',
                                         sort_value: "exists(#{Search::Fields::LAST_DEPOSITED_DATE}) desc, " \
                                                     "#{Search::Fields::LAST_DEPOSITED_DATE} asc, id asc")
    LAST_DEPOSITED_DATE_DESC = Config.new(label: 'Last deposited date (descending)',
                                          sort_value: "exists(#{Search::Fields::LAST_DEPOSITED_DATE}) desc, " \
                                                      "#{Search::Fields::LAST_DEPOSITED_DATE} desc, id asc")
    REGISTERED_DATE_ASC = Config.new(label: 'Registered date (ascending)',
                                     sort_value: "#{Search::Fields::EARLIEST_REGISTERED_DATE} asc, id asc")
    REGISTERED_DATE_DESC = Config.new(label: 'Registered date (descending)',
                                      sort_value: "#{Search::Fields::EARLIEST_REGISTERED_DATE} desc, id asc")
    SOURCE_ID = Config.new(label: 'Source ID', sort_value: "#{Search::Fields::SOURCE_ID} asc, id asc")
    TITLE = Config.new(label: 'Title', sort_value: "#{Search::Fields::SORT_TITLE} asc, id asc")
    DRUID = Config.new(label: 'Druid', sort_value: 'id asc')
  end
end
