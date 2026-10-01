# frozen_string_literal: true

module StructuralCsv
  # Builds (but does not save) ContentFileSets and ContentFiles from validated structural metadata CSV rows,
  # carrying over the identity and values of the Content's existing ContentFileSets and ContentFiles.
  # See StructuralCsv::Import for the columns and how blank cells are handled.
  #
  # The order of the groups is the new order of the file sets. A group's sequence is the position of an existing
  # file set (if there is one at that position), whose identity and values are carried over. Gaps are allowed: with
  # 3 existing file sets and sequences 1, 2, 5, the result is existing file set 1, existing file set 2, and a new
  # file set.
  class ContentFileSetsBuilder
    DEFAULT_FILE_SET_TYPE = 'object'

    # A built ContentFileSet, with the rows it was built from and its built ContentFiles (in the same order as the rows)
    BuiltContentFileSet = Struct.new(:rows, :content_file_set, :content_files)

    def self.call(...)
      new(...).call
    end

    # @param groups [Array<Array<Row>>] the validated rows, grouped by sequence
    # @param content [Content]
    # @param content_file_binaries_by_filepath [Hash<String, ContentFileBinary>] the Content's binaries. The mime
    #   types of these binaries are updated (but not saved).
    def initialize(groups:, content:, content_file_binaries_by_filepath:)
      @groups = groups
      @content = content
      @content_file_binaries_by_filepath = content_file_binaries_by_filepath
    end

    # @return [Array<BuiltContentFileSet>]
    def call
      groups.map do |rows|
        existing_content_file_set = existing_content_file_sets_by_position[rows.first.sequence]
        content_file_set = build_content_file_set(row: rows.first, existing_content_file_set:)
        content_files = rows.map do |row|
          build_content_file(row:, content_file_set:, existing_content_file: existing_content_files_by_row[row])
        end
        BuiltContentFileSet.new(rows, content_file_set, content_files)
      end
    end

    private

    attr_reader :groups, :content, :content_file_binaries_by_filepath

    # Note that content_id (rather than content) is set so that the ContentFileSet is not added to
    # content.content_file_sets (and so destroyed along with the existing ContentFileSets).
    def build_content_file_set(row:, existing_content_file_set:)
      ContentFileSet.new(
        content_id: content.id,
        label: row.fetch('resource_label') { existing_content_file_set&.label || '' },
        file_set_type: row.fetch('resource_type') { existing_content_file_set&.file_set_type || DEFAULT_FILE_SET_TYPE },
        external_identifier: existing_content_file_set&.external_identifier
      )
    end

    def build_content_file(row:, content_file_set:, existing_content_file:)
      content_file_binary = content_file_binaries_by_filepath.fetch(row.filename)
      content_file_binary.mime_type = row.value('mimetype') if row.present?('mimetype')

      content_file_set.content_files.build(
        content_file_binary:,
        **access_attributes(row),
        **administrative_attributes(row),
        **descriptive_attributes(row:, existing_content_file:),
        external_identifier: existing_content_file&.external_identifier,
        width: existing_content_file&.width,
        height: existing_content_file&.height
      )
    end

    # Location only applies to location-based access.
    def access_attributes(row)
      {
        view: row.value('rights_view'),
        download: row.value('rights_download'),
        location: row.location_based? ? row.value('rights_location').presence : nil
      }
    end

    def administrative_attributes(row)
      {
        publish: row.boolean('publish'),
        preserve: row.boolean('preserve'),
        shelve: row.fetch_boolean('shelve') { row.boolean('publish') }
      }
    end

    def descriptive_attributes(row:, existing_content_file:)
      {
        label: row.fetch('file_label') { existing_content_file&.label || '' },
        language_tag: row.fetch('file_language') { existing_content_file&.language_tag }.presence,
        use: row.fetch('role') { existing_content_file&.use }.presence,
        **accessibility_attributes(row:, existing_content_file:)
      }
    end

    # For these optional boolean columns, a blank cell is false.
    def accessibility_attributes(row:, existing_content_file:)
      %i[sdr_generated_text corrected_for_accessibility].index_with do |attribute|
        row.fetch_boolean(attribute.to_s) { existing_content_file&.public_send(attribute) } || false
      end
    end

    # Each existing ContentFile is matched to at most one row, so that external identifiers are not duplicated.
    # A row is matched first to the file with the same filename in the existing file set at the row's sequence.
    # Otherwise, it is matched to the first unmatched file anywhere in the Content referencing the same binary
    # (so a file moved to a different file set keeps its identity and dimensions).
    # @return [Hash<Row, ContentFile>]
    def existing_content_files_by_row
      @existing_content_files_by_row ||= {}.compare_by_identity.tap do |matches|
        rows = groups.flatten
        # All same file set matches are made first, so that they take precedence over same binary matches.
        match_rows(matches:, rows:) { |row| same_position_content_files(row) }
        match_rows(matches:, rows: rows.reject { |row| matches.key?(row) }) { |row| same_binary_content_files(row) }
      end
    end

    # Matches each row to the first of its candidate ContentFiles (yielded) that is not already matched.
    def match_rows(matches:, rows:)
      matched_ids = matches.each_value.to_set(&:id)
      rows.each do |row|
        content_file = yield(row).find { |candidate| matched_ids.exclude?(candidate.id) }
        next unless content_file

        matches[row] = content_file
        matched_ids << content_file.id
      end
    end

    def same_position_content_files(row)
      content_file_set = existing_content_file_sets_by_position[row.sequence]
      return [] unless content_file_set

      content_file_set.content_files.select { |content_file| content_file.filepath == row.filename }
    end

    def same_binary_content_files(row)
      existing_content_files_by_binary_id.fetch(content_file_binaries_by_filepath.fetch(row.filename).id, [])
    end

    def existing_content_file_sets_by_position
      @existing_content_file_sets_by_position ||= content.content_file_sets
                                                         .includes(content_files: :content_file_binary)
                                                         .index_by(&:position)
    end

    # The existing ContentFiles for each binary, in file set and then file order.
    def existing_content_files_by_binary_id
      @existing_content_files_by_binary_id ||= existing_content_file_sets_by_position.sort.map(&:last)
                                                                                     .flat_map(&:content_files)
                                                                                     .group_by(&:content_file_binary_id)
    end
  end
end
