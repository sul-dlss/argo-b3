# frozen_string_literal: true

module BulkActions
  # Form object for manage embargo bulk action.
  class ManageEmbargoForm < BasicCsvForm
    REQUIRED_HEADERS = %w[druid release_date view download].freeze
    LOCATION_BASED = 'location-based'

    private

    def validate_csv_file
      validator = CsvUpload::Validator.new(csv: normalized_csv_file, required_headers: REQUIRED_HEADERS)
      valid = validator.valid? { |csv| missing_location_header_message(csv) }
      return if valid

      validator.errors.each do |message|
        errors.add(:csv_file, :invalid, message:)
      end
    end

    # The location header is only required when a row's view or download access is location-based.
    def missing_location_header_message(csv)
      return if csv.headers.include?('location')
      return unless csv.any? { |row| [row['view'], row['download']].include?(LOCATION_BASED) }

      'missing headers: location.'
    end
  end
end
