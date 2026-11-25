# frozen_string_literal: true

module StructuralCsv
  # Validates the access rights of a structural metadata CSV row: first each value, and then (only if view and
  # download are present and every value is allowed) their combination, so that a missing value or one that is not
  # allowed is not also reported as an invalid combination. Missing values are reported by Validator.
  # The location is used only for location-based access (see ContentFileSetsBuilder), so it is otherwise ignored.
  class AccessValidator
    VALUE_CHECKS = [
      ['rights_view', 'view access', AccessRightsSupport::FILE_VIEW_RIGHTS],
      ['rights_download', 'download access', AccessRightsSupport::DOWNLOAD_RIGHTS]
    ].freeze

    def self.call(...)
      new(...).call
    end

    # @param row [Row]
    def initialize(row:)
      @row = row
    end

    # @return [Array<String>] the reasons the access rights are not valid
    def call
      value_errors = view_and_download_errors + location_errors
      return value_errors if value_errors.any?
      return [] if row.blank?('rights_view') || row.blank?('rights_download') || valid_combination?

      [combination_error]
    end

    private

    attr_reader :row

    def view_and_download_errors
      VALUE_CHECKS.filter_map do |column, kind, allowed_values|
        next if row.blank?(column) || allowed_values.include?(row.value(column))

        value_error(column, kind)
      end
    end

    # A blank location is reported (if location-based) as an invalid combination.
    def location_errors
      return [] if location.nil? || Constants::ACCESS_LOCATIONS.include?(location)

      [value_error('rights_location', 'location')]
    end

    def value_error(column, kind)
      "Value for \"#{column}\" (\"#{row.value(column)}\") is not a valid #{kind}"
    end

    def valid_combination?
      AccessRightsSupport.valid?(view: row.value('rights_view'), download: row.value('rights_download'), location:,
                                 citation_only: false)
    end

    def location
      row.location_based? ? row.value('rights_location').presence : nil
    end

    # The values are as they are in the CSV (including an ignored location), so that the user can find them.
    def combination_error
      "Access rights (#{described_value('view', 'rights_view')}, #{described_value('download', 'rights_download')}, " \
        "#{described_value('location', 'rights_location')}) are not a valid combination"
    end

    def described_value(name, column)
      row.blank?(column) ? "#{name} blank" : "#{name} \"#{row.value(column)}\""
    end
  end
end
