# frozen_string_literal: true

module Show
  # Component for displaying the technical metadata for a file.
  class TechnicalMetadataComponent < ApplicationComponent
    # The druid and filename are excluded since they are already known from the file being displayed.
    EXCLUDED_KEYS = %w[druid filename].freeze

    # @param technical_metadata [Hash] technical metadata for the file (a DroFile per the techmd OpenAPI spec)
    def initialize(technical_metadata:)
      @technical_metadata = technical_metadata
      super()
    end

    def display_hash
      technical_metadata.except(*EXCLUDED_KEYS).tap do |hash|
        hash['bytes'] = helpers.number_to_human_size(hash['bytes']) if hash['bytes']
        hash['file_modification'] = file_modification_label(hash['file_modification']) if hash['file_modification']
      end
    end

    private

    attr_reader :technical_metadata

    def file_modification_label(file_modification)
      helpers.format_datetime(Time.zone.parse(file_modification))
    end
  end
end
