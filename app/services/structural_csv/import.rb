# frozen_string_literal: true

module StructuralCsv
  # Service for updating structural metadata from CSV rows (in the format produced by StructureSerializer).
  #
  # It's not possible to add a new file without going through the accessioning process.
  # So CSV rows that list a file not already present are rejected.
  # At present, the CSV update only supports changing settings,
  # changing the order of resources, or removing content.
  class Import
    include Dry::Monads[:result]

    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::DRO, Cocina::Models::DROWithMetadata] the object to update
    # @param csv_rows [Array<CSV::Row>] the rows for the object. Any druid column is ignored.
    # @param line_numbers [Array<Integer>] the spreadsheet line number of each row (used in error messages).
    #   Defaults to numbering the rows consecutively, starting at 2 (the line after the header).
    def initialize(cocina_object:, csv_rows:, line_numbers: nil)
      @cocina_object = cocina_object
      @csv_rows = csv_rows
      @line_numbers = line_numbers || (2..(csv_rows.size + 1)).to_a
      raise ArgumentError, 'line_numbers must have one entry per row' unless @line_numbers.size == csv_rows.size
    end

    # @return [Dry::Monads::Success(Cocina::Models::DROStructural)] if there are no problems
    # @return [Dry::Monads::Failure(Array<String>)] error messages if there are problems
    def call
      errors = validate
      return Failure(errors) if errors.present?

      Success(cocina_object.structural.new(contains: build_file_sets))
    end

    private

    attr_reader :cocina_object, :csv_rows, :line_numbers

    # @return [Array<String>] error messages
    def validate
      csv_rows.zip(line_numbers).flat_map do |row, index|
        row_errors(row).map { |message| "On row #{index} found #{message}" }
      end
    end

    # @return [Array<String>] error messages for the row, without the row prefix
    def row_errors(row)
      errors = []
      errors << "\"#{row['resource_type']}\", which is not a valid resource type" if invalid_resource_type?(row)
      if invalid_sequence?(row)
        errors << "\"#{row['sequence']}\", which is not a valid sequence (must be a positive integer)"
      end
      return errors << "#{row['filename']}, which appears to be a new file" unless existing_file?(row)

      errors + file_errors(row).map { |message| "#{row['filename']}, #{message}" }
    end

    # @return [Array<String>] error messages for an existing file in the row
    def file_errors(row)
      [].tap do |errors|
        errors << 'which changed preserve from no to yes, which is not supported' if invalid_preservation_change?(row)
        if shelve_without_publish_or_preserve?(row)
          errors << 'which has shelve=yes with publish=no and preserve=no, ' \
                    'which would cause the file to be deleted from all systems'
        end
        if invalid_location_rights?(row)
          errors << 'which set view or download rights to location-based but did not specify a location'
        end
      end
    end

    # Ensure all files in the csv are present in the existing object
    def existing_file?(row)
      existing_files_by_filename.key?(row['filename'])
    end

    # Ensure no existing files change preserve from no to yes
    def invalid_preservation_change?(row)
      existing_files_by_filename[row['filename']].administrative.sdrPreserve == false && row['preserve'] == 'yes'
    end

    # Ensure no files are set to shelve=yes with both publish and preserve disabled,
    # which would cause the file to be deleted from all systems at end of accessioning
    def shelve_without_publish_or_preserve?(row)
      row['shelve'] == 'yes' && row['publish'] == 'no' && row['preserve'] == 'no'
    end

    # Ensure no files set location-based access without specifying a location
    def invalid_location_rights?(row)
      [row['rights_view'], row['rights_download']].include?('location-based') && row['rights_location'].blank?
    end

    # Ensure all supplied sequences are positive integers
    def invalid_sequence?(row)
      !row['sequence'].to_s.strip.match?(/\A\d+\z/) || row['sequence'].to_i < 1
    end

    # Ensure all supplied resource types are valid
    def invalid_resource_type?(row)
      !Cocina::Models::FileSetType.properties.key?(row['resource_type'].to_s.to_sym)
    end

    def existing_files_by_filename
      @existing_files_by_filename ||= Array(cocina_object.structural&.contains).each_with_object({}) do |file_set, hash|
        file_set.structural.contains.each do |file|
          hash[file.filename] = file
        end
      end
    end

    def build_file_sets
      # Group the rows by sequence, preserving the order in which each sequence first appears.
      csv_rows.group_by { |row| row['sequence'].to_i }.map { |sequence, rows| build_file_set(sequence, rows) }
    end

    def build_file_set(sequence, rows)
      files = rows.map { |row| update_file(existing_files_by_filename[row['filename']], row) }
      # The last row for a sequence determines the file set's label and type.
      last_row = rows.last
      file_set_for(sequence, files.first.label).new(
        label: last_row['resource_label'] || '',
        type: file_set_type(last_row['resource_type']),
        structural: { contains: files }
      )
    end

    # Attributes that are replaced with values from the CSV row. Other attributes are retained from the existing file.
    # Blank values are omitted (rather than set to nil) so that unchanged files compare as equal.
    def update_file(existing_file, row) # rubocop:disable Metrics/AbcSize
      attributes = {
        label: row['file_label'] || '',
        hasMimeType: row['mimetype'],
        use: row['role'],
        languageTag: row['file_language'],
        sdrGeneratedText: to_boolean(row['sdr_generated_text']),
        correctedForAccessibility: to_boolean(row['corrected_for_accessibility']),
        administrative: {
          publish: row['publish'] == 'yes',
          shelve: row['shelve'] == 'yes',
          sdrPreserve: row['preserve'] == 'yes'
        },
        access: file_access(row)
      }
      existing_file.class.new(existing_file.to_h.except(*attributes.keys).merge(attributes.compact))
    end

    def file_access(row)
      {
        view: row['rights_view'],
        download: row['rights_download'],
        location: row['rights_location'],
        # stanford/none requires controlledDigitalLending set to false. All others should omit.
        controlledDigitalLending: row['rights_view'] == 'stanford' && row['rights_download'] == 'none' ? false : nil
      }.compact
    end

    # @param sequence [Integer] the (1-based) position of the file set in the import
    # @param label [String] the label for a new file set
    # @return [Cocina::Models::FileSet] the existing file set at the sequence's position or a new file set
    def file_set_for(sequence, label)
      cocina_object.structural.contains[sequence - 1].presence ||
        Cocina::Models::FileSet.new(externalIdentifier: new_file_set_external_identifier,
                                    type: Cocina::Models::FileSetType.file,
                                    label:,
                                    version: 1)
    end

    # Follows the minting strategy in Contents::ExternalIdentifierMinter.
    def new_file_set_external_identifier
      "#{Contents::ExternalIdentifierMinter::ID_NAMESPACE}/fileSet/" \
        "#{DruidSupport.bare_druid_from(cocina_object.externalIdentifier)}-#{SecureRandom.uuid}"
    end

    # Change the short resource type into a URI
    def file_set_type(resource_type)
      Cocina::Models::FileSetType.properties[resource_type.to_sym]
    end

    def to_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value) || false
    end
  end
end
