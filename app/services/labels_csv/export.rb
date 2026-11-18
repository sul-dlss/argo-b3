# frozen_string_literal: true

module LabelsCsv
  # Service for serializing the resource labels of a Content to CSV, one row per resource in order.
  class Export
    HEADERS = %w[druid sequence resource_label].freeze

    def self.as_csv(content:)
      new(content:).as_csv
    end

    # @param content [Content] the Content to serialize
    def initialize(content:)
      @content = content
    end

    def as_csv
      druid = DruidSupport.bare_druid_from(content.druid)
      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        content.content_file_sets.each.with_index(1) do |content_file_set, sequence|
          csv << [druid, sequence, content_file_set.label]
        end
      end
    end

    private

    attr_reader :content
  end
end
