# frozen_string_literal: true

# Methods for working with hierarchical facet values
# Hierarchical values have the format: [LEVEL]|[VALUES]|[LEAF OR BRANCH]
# VALUES are colon-separated (with or without whitespace)
# For example: "3|accessionWF:start-accession:completed|-"
class HierarchicalValueSupport
  DELIMITER = '|'
  LEAF_SYMBOL = '-'
  BRANCH_SYMBOL = '+'

  # @param value [String, nil] values (no level and branch indicators) or hierarchical value
  # @return [Integer, nil] the level of the facet value
  def self.level(value)
    return if value.nil?

    value.scan(/\s*:\s*/).size + 1
  end

  # @param hierarchical_value [String, nil] hierarchical value
  # @return [Array<String>, nil] split into [level, values, leaf_or_branch]
  def self.split(hierarchical_value)
    return if hierarchical_value.nil?

    split_value = hierarchical_value.split(DELIMITER)
    raise ArgumentError, "Invalid hierarchical value: #{hierarchical_value}" if split_value.size != 3

    split_value[0] = split_value[0].to_i
    split_value
  end

  # @param value [String, nil] values (no level and branch indicators) or hierarchical value
  # @return [Array<String>, nil] the parts of the value
  def self.value_parts(value)
    return if value.nil?

    split_value = value.split(DELIMITER)
    value_to_split = split_value[1] || value

    value_to_split.split(/\s*:\s*/)
  end
end
