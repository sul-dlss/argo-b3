# frozen_string_literal: true

module DescriptiveCsv
  # This class faciliates the export of cocina descriptive metadata to a hash and to CSV
  #
  # Exporting is two steps:
  # 1. `.export` flattens the description of ONE object into a single row (a hash of column name => value).
  # 2. `.as_csv` combines the rows of ONE OR MORE objects (keyed by druid) into a CSV string. Since objects
  #    can have different columns (e.g., one has two titles, another has one), it unions and orders the columns.
  #
  # For example:
  #   rows = { druid => DescriptiveCsv::Export.export(source_id:, description:) }
  #   DescriptiveCsv::Export.as_csv(descriptions: rows)
  class Export
    # Builds CSV (as a string) using the hashes of descriptions first produced by `.export`.
    # This can then be written to disk or streamed as needed by the consumer.
    # @param descriptions [Hash<String, Hash>] druids mapped to the row from `.export`
    # @return [String] CSV text with a header row (`druid` plus the combined columns) and one row per druid
    def self.as_csv(descriptions:)
      grouped_descriptions = DescriptionsGrouper.group(descriptions:)
      ordered_headers = Headers.create(headers: grouped_descriptions.values.flat_map(&:keys).uniq)

      CSV.generate(write_headers: true, headers: %w[druid] + ordered_headers) do |csv|
        grouped_descriptions.each do |druid, description|
          csv << ([DruidSupport.bare_druid_from(druid)] + description.values_at(*ordered_headers))
        end
      end
    end

    # Flattens the description of a single object to a hash.
    # @return [Hash<String, String>] column name => value
    def self.export(source_id:, description:)
      new(source_id:, description:).export
    end

    def initialize(source_id:, description:)
      @description = description
      @source_id = source_id.presence || '' # identification.sourceId is not a required property.
    end

    def export
      flatten(squish(description.to_h).merge('source_id' => @source_id))
    end

    # Transform the COCINA datastructure into a hash structure by converting
    # arrays to hashes with index (starting at 1) as the key
    def squish(source)
      return source unless source.is_a? Hash

      source.each_with_object({}) do |(k, value), sink|
        new_value = if value.is_a? Array
                      # Transform to hash
                      value.each_with_object({}).with_index(1) { |(el, acc), index| acc[index] = squish(el) }
                    else
                      squish(value)
                    end
        sink[k.to_s] = new_value.presence
      end.compact
    end

    # Change the nested hash structure into a single level hash
    def flatten(source)
      source.each_with_object({}) do |(key, value), sink|
        if value.is_a? String
          sink[key] = value
        else
          flatten(value).each do |k, v|
            new_key = k.start_with?(/\d/) ? "#{key}#{k}" : "#{key}.#{k}"
            sink[new_key] = v
          end
        end
      end
    end

    attr_reader :description
  end
end
