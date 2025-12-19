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

    RELEVANCE = Config.new(label: 'Relevance', sort_value: 'score desc')
    DRUID = Config.new(label: 'Druid', sort_value: 'id asc')
  end
end
