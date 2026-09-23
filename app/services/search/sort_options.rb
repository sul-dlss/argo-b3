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

    Config = Struct.new(:label, :sort_value)

    # Secondary sorts on druid keep paging stable when objects share a date or source id.
    RELEVANCE = Config.new(label: 'Relevance', sort_value: 'score desc')
    LAST_DEPOSITED_DATE_ASC = Config.new(label: 'Last deposited date (ascending)',
                                         sort_value: "#{Search::Fields::LAST_DEPOSITED_DATE} asc, id asc")
    LAST_DEPOSITED_DATE_DESC = Config.new(label: 'Last deposited date (descending)',
                                          sort_value: "#{Search::Fields::LAST_DEPOSITED_DATE} desc, id asc")
    REGISTERED_DATE_ASC = Config.new(label: 'Registered date (ascending)',
                                     sort_value: "#{Search::Fields::EARLIEST_REGISTERED_DATE} asc, id asc")
    REGISTERED_DATE_DESC = Config.new(label: 'Registered date (descending)',
                                      sort_value: "#{Search::Fields::EARLIEST_REGISTERED_DATE} desc, id asc")
    SOURCE_ID = Config.new(label: 'Source ID', sort_value: "#{Search::Fields::SOURCE_ID} asc, id asc")
    TITLE = Config.new(label: 'Title', sort_value: "#{Search::Fields::SORT_TITLE} asc, id asc")
    DRUID = Config.new(label: 'Druid', sort_value: 'id asc')
  end
end
