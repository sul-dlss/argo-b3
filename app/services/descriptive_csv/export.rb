# frozen_string_literal: true

module DescriptiveCsv
  # This exports the cocina description to a rectangularized data structure
  class Export
    # Builds a CSV (as a string) from descriptions.
    # @param descriptions [Hash<String, Hash>] descriptions mapped to a csv row
    def self.as_csv(descriptions:)
      grouped_descriptions = DescriptionsGrouper.group(descriptions:)
      ordered_headers = Headers.create(headers: grouped_descriptions.values.flat_map(&:keys).uniq)

      CSV.generate(write_headers: true, headers: %w[druid] + ordered_headers) do |csv|
        grouped_descriptions.each do |druid, description|
          csv << ([DruidSupport.bare_druid_from(druid)] + description.values_at(*ordered_headers))
        end
      end
    end

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
