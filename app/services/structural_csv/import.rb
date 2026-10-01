# frozen_string_literal: true

module StructuralCsv
  # Updates a Content's file sets and files from the structural metadata CSV rows for a single object (roughly
  # equivalent to Argo's StructureUpdater). Files cannot be added; rows can only change settings, reorder or regroup
  # files, or (by omission) remove files.
  #
  # The CSV may have the following headers:
  # - druid (required; used by the caller to group rows by object)
  # - resource_label
  # - resource_type
  # - sequence (required; the position of an existing file set, not the new position - see ContentFileSetsBuilder)
  # - filename (required)
  # - file_label
  # - publish (boolean; required)
  # - shelve (boolean)
  # - preserve (boolean; required)
  # - rights_view (required)
  # - rights_download (required)
  # - rights_location (required)
  # - mimetype
  # - role
  # - file_language
  # - sdr_generated_text (boolean)
  # - corrected_for_accessibility (boolean)
  #
  # A column that is present is always used, including when a cell is blank: a blank cell is either a
  # meaningful value or a validation error, never a fallback to the existing value. Only an absent column
  # falls back.
  #
  # | Column                       | Present, blank                         | Absent                          |
  # |------------------------------|----------------------------------------|---------------------------------|
  # | resource_label               | ''                                     | existing label, or ''           |
  # | resource_type                | error                                  | existing type, or 'object'      |
  # | file_label                   | ''                                     | existing label, or ''           |
  # | file_language                | nil                                    | existing language_tag, or nil   |
  # | role                         | nil                                    | existing use, or nil            |
  # | mimetype                     | error                                  | binary's existing mime_type     |
  # | sdr_generated_text           | false                                  | existing value, or false        |
  # | corrected_for_accessibility  | false                                  | existing value, or false        |
  # | shelve                       | error                                  | publish                         |
  # | publish, preserve            | error                                  | (required column)               |
  # | rights_view, rights_download | error                                  | (required column)               |
  # | rights_location              | nil (valid unless location-based)      | (required column)               |
  # | sequence, filename           | error                                  | (required column)               |
  #
  # Boolean cells must be "yes", "no", "true", or "false" (case-insensitive).
  class Import
    include Dry::Monads[:result]

    def self.call(...)
      new(...).call
    end

    # @param rows [Array<Array(Integer, CSV::Row)>] the rows for a single object, each paired with its spreadsheet
    #   row number (used in error messages). Rows for an object need not be contiguous in the spreadsheet.
    # @param content [Content] the mutable Content to update, whose ContentFileBinaries the rows are matched against
    #   by filename
    # @raise [ArgumentError] if the Content is immutable
    def initialize(rows:, content:)
      raise ArgumentError, 'Content must be mutable' if content.immutable?

      # Build StructuralCsv:Rows (not CSV:Rows)
      @rows = rows.map { |number, csv_row| Row.new(number:, csv_row:) }
      @content = content
    end

    # Nothing is saved unless the rows and the built records are all valid.
    # @return [Dry::Monads::Result] Success if the content was successfully updated, or
    #   Failure with an Array<ValidationError>
    def call
      errors = Validator.call(rows:, content_file_binaries_by_filepath:)
      return Failure(errors) if errors.any?

      built_content_file_sets = build_content_file_sets
      errors = built_content_file_sets.flat_map { |built_content_file_set| model_errors(built_content_file_set) }
      return Failure(errors) if errors.any?

      save(built_content_file_sets)
      Success()
    end

    private

    attr_reader :rows, :content

    # Entirely blank rows are ignored (as they are by the Validator).
    def build_content_file_sets
      ContentFileSetsBuilder.call(groups: Row.groups(rows.reject(&:entirely_blank?)), content:,
                                  content_file_binaries_by_filepath:)
    end

    def content_file_binaries_by_filepath
      @content_file_binaries_by_filepath ||= content.content_file_binaries.includes(:content_files).index_by(&:filepath)
    end

    # ContentFileSet errors are reported on the first row of the file set; ContentFile errors on the file's row.
    # @return [Array<ValidationError>]
    def model_errors(built_content_file_set)
      content_file_set_errors(built_content_file_set) +
        built_content_file_set.rows.zip(built_content_file_set.content_files).flat_map do |row, content_file|
          content_file_errors(row:, content_file:)
        end
    end

    def content_file_set_errors(built_content_file_set)
      content_file_set = built_content_file_set.content_file_set
      content_file_set.valid?
      # The ContentFiles' errors (e.g., content_files or content_files.shelve) are reported separately (on their rows).
      content_file_set.errors.reject { |error| error.attribute.to_s.start_with?('content_files') }.map do |error|
        ValidationError.new(built_content_file_set.rows.first.number, error.full_message)
      end
    end

    def content_file_errors(row:, content_file:)
      return [] if content_file.valid?

      content_file.errors.full_messages.map { |message| ValidationError.new(row.number, "#{row.filename}: #{message}") }
    end

    def save(built_content_file_sets)
      ActiveRecord::Base.transaction do
        # Not clear, which deletes with SQL and so would not destroy the ContentFiles.
        content.content_file_sets.destroy_all
        # Saved in order, so that the file sets (and their files) are positioned in order.
        built_content_file_sets.each { |built_content_file_set| built_content_file_set.content_file_set.save! }
        content_file_binaries_by_filepath.each_value.select(&:changed?).each(&:save!)
        destroy_unassociated_content_file_binaries
      end
      # The Content's loaded associations no longer reflect the saved file sets.
      content.reload
    end

    # Staged copies are deleted by Contents::ContentFileBinaryDestroyer after the transaction commits.
    def destroy_unassociated_content_file_binaries
      Contents::ContentFileBinaryDestroyer.call(
        content_file_binaries: content.content_file_binaries.unassociated.includes(:content).to_a
      )
    end
  end
end
