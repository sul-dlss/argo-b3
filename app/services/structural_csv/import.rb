# frozen_string_literal: true

module StructuralCsv
  # Updates a Content's file sets and files from the CSV rows for a single object (roughly equivalent to Argo's
  # StructureUpdater). Files cannot be added; rows can only change settings, reorder or regroup files, or (by
  # omission) remove files.
  class Import
    include Dry::Monads[:result]

    ValidationError = Struct.new(:line_number, :reason)

    # The CSV may have the following headers:
    # - druid (required; used by the caller to group rows by object)
    # - resource_label
    # - resource_type
    # - sequence (required; the position of an existing file set, not the new position - see below)
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
    # | Column                      | Present, blank                                | Absent                          |
    # |-----------------------------|-----------------------------------------------|---------------------------------|
    # | resource_label              | ''                                            | existing label, or ''           |
    # | resource_type               | error                                         | existing type, or 'object'      |
    # | file_label                  | ''                                            | existing label, or ''           |
    # | file_language               | nil                                           | existing language_tag, or nil   |
    # | role                        | nil                                           | existing use, or nil            |
    # | mimetype                    | error                                         | binary's existing mime_type     |
    # | sdr_generated_text          | false                                         | existing value, or false        |
    # | corrected_for_accessibility | false                                         | existing value, or false        |
    # | shelve                      | error                                         | publish                         |
    # | publish, preserve           | error                                         | (required column)               |
    # | rights_view, rights_download| error                                         | (required column)               |
    # | rights_location             | nil (valid unless view/download is            | (required column)               |
    # |                             | location-based)                               |                                 |
    # | sequence, filename          | error (see blank row handling below)          | (required column)               |
    #
    # Boolean cells must be "yes", "no", "true", or "false" (case-insensitive, surrounding whitespace stripped).
    REQUIRED_COLUMNS = %w[druid sequence filename publish preserve rights_view rights_download rights_location].freeze

    # @param rows [Array<Array(Integer, CSV::Row)>] the rows for a single object, each paired with its spreadsheet
    #   row number (used in error messages). Rows for an object need not be contiguous in the spreadsheet.
    # @param content [Content] the mutable Content to update, whose ContentFileBinaries the rows are matched against
    #   by filename
    # @raise [ArgumentError] if the Content is immutable
    def initialize(rows:, content:)
      raise ArgumentError, 'Content must be mutable' if content.immutable?

      @rows = rows
      @content = content
    end

    # @return [Dry::Monads::Result] Success if the content was successfully updated, or
    #   Failure with an Array<ValidationError>
    def call
      # PHASE 1 - Columns
      # The caller (BulkActions::ImportStructuralMetadataJob) also checks this, once for the whole CSV.
      # For each of REQUIRED_COLUMNS that is missing from the headers:
      #   ValidationError(line_number: 1, reason: "Missing required column \"<name>\"")
      # If any errors, return Failure (row checks would just be noise).
      #
      # PHASE 2 - Rows
      # Collect errors across all rows, then return Failure if there are any. No records are built in this phase.
      #
      # Drop rows that are entirely blank. A row with any value but a blank filename is an error.
      # If no rows remain, error (an import cannot empty an object's structure).
      #
      # For every row:
      #   Validate sequence is a positive integer.
      #   Validate rights_view and rights_download are not blank.
      #   Validate publish and preserve, and shelve (if column present), are not blank and are booleans (see above).
      #   Validate sdr_generated_text and corrected_for_accessibility (if columns present) are blank or booleans.
      #   Validate resource_type (if column present) is not blank.
      #   Validate mimetype (if column present) is not blank.
      #   Find the ContentFileBinary where row's filename = ContentFileBinary.filepath:
      #     Validate that there is a ContentFileBinary (no files added).
      #     If the row is preserve=yes and the ContentFileBinary is file_location=deposited, for the first of the
      #     ContentFileBinary's ContentFiles:
      #       Validate that the ContentFile is not preserve=false (preserve can't go from no to yes).
      #
      # If mimetype column is present, validate that every row with the same filename has the same mimetype
      # (mime_type is stored on the ContentFileBinary, so is shared by every file that references it).
      #
      # Group the rows by sequence, preserving the order in which each sequence first appears.
      # Validate that the rows for each sequence are contiguous (error on the row where a sequence reappears).
      # For each group:
      #   Validate that resource_label and resource_type (if columns present) are the same for every row.
      #   Validate that no filename appears more than once (the same filename in different groups is allowed;
      #   it becomes multiple ContentFiles referencing the same ContentFileBinary).
      #
      # PHASE 3 - Build (in memory; nothing is saved in this phase)
      # The order of the groups is the new order of the file sets. A group's sequence is the position of an existing
      # file set (if there is one at that position), whose identity and values are carried over. Existing file sets
      # whose position is not referenced by any sequence are removed. Gaps are allowed: with 3 existing file sets
      # and sequences 1, 2, 5, the result is existing file set 1, existing file set 2, and a new file set; existing
      # file set 3 is removed.
      #
      # For each group:
      #   Get the existing ContentFileSet with position = sequence (if present).
      #   Using the first row in the group, initialize a new ContentFileSet, setting (see table above):
      #   - label = resource_label
      #   - file_set_type = resource_type
      #   - external_identifier = existing ContentFileSet's external_identifier (if present; otherwise minted later
      #     by Contents::ExternalIdentifierMinter)
      #   Record the group's first row number for the ContentFileSet (for reporting its validation errors).
      #   For each row (in row order, which is the new order of the files):
      #     Get the existing ContentFile:
      #     - first, from the existing ContentFileSet's content_files where row's filename = filepath
      #     - otherwise, the first ContentFile anywhere in the Content referencing the row's ContentFileBinary
      #       (so a file moved to a different file set keeps its identity and dimensions)
      #     Initialize a new ContentFile, setting (see table above):
      #     - content_file_set = the new ContentFileSet
      #     - content_file_binary = the ContentFileBinary where row's filename = filepath
      #     - label = file_label
      #     - view = rights_view
      #     - download = rights_download
      #     - location = rights_location if rights_view or rights_download is location-based, otherwise nil
      #     - preserve = preserve, cast to boolean
      #     - publish = publish, cast to boolean
      #     - shelve = shelve, cast to boolean
      #     - language_tag = file_language
      #     - use = role
      #     - sdr_generated_text = sdr_generated_text
      #     - corrected_for_accessibility = corrected_for_accessibility
      #     - external_identifier = existing ContentFile's external_identifier (if present)
      #     - width = existing ContentFile's width (if present)
      #     - height = existing ContentFile's height (if present)
      #     If mimetype column is present, set the ContentFileBinary's mime_type (unsaved).
      #
      # Validate each new ContentFileSet and ContentFile (and changed ContentFileBinary), creating a ValidationError
      # with the row number for each error (ContentFileSet errors use the group's first row number).
      # If any errors, return Failure. Nothing has been saved.
      #
      # SAVE (in a single transaction)
      # Note that all values carried over from existing records must already be in memory, since they are destroyed.
      # Destroy the existing ContentFileSets with content.content_file_sets.destroy_all (not clear, which deletes with
      # SQL and so would not destroy the ContentFiles).
      # Save the new ContentFileSets (in order, so that positioned assigns positions 1..n) and their ContentFiles.
      # Save the updated ContentFileBinaries.
      # Destroy the now unassociated ContentFileBinaries with Contents::ContentFileBinaryDestroyer (which also
      # deletes any staged copies after the transaction commits).
      #
      # Return Success
    end

    private

    attr_reader :rows, :content
  end
end
