# frozen_string_literal: true

module Contents
  # Determines whether a mutable Content has unsaved changes, i.e., changes not yet staged to the Cocina object.
  # Only the attributes that a user can change when managing files are compared.
  class UnsavedChanges
    FILE_SET_COLUMNS = %w[file_set_type label].freeze
    FILE_COLUMNS = %w[label use view download location language_tag corrected_for_accessibility sdr_generated_text
                      publish preserve shelve].freeze
    BINARY_COLUMNS = %w[filepath mime_type].freeze
    UNSTAGED_FILE_LOCATIONS = %w[attached mount globus].freeze

    def self.call(...)
      new(...).call
    end

    # @param content [Content, nil] the mutable Content for the Cocina object's lock
    # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object
    def initialize(content:, cocina_object:)
      @content = content
      @cocina_object = cocina_object
    end

    # @return [Boolean] true if the Content has unsaved changes
    def call
      return false if content.nil?
      # New files (including those not yet added to a resource) are only saved by staging.
      return true if content.content_file_binaries.exists?(file_location: UNSTAGED_FILE_LOCATIONS)

      content_structure != cocina_structure
    end

    private

    attr_reader :content, :cocina_object

    # Plucked rather than loaded, since a Content may have many files.
    # @return [Array<Array>] for each resource in order, its attributes and the attributes of its files in order
    def content_structure
      files_by_file_set_id = content_files_by_file_set_id
      content.content_file_sets.pluck(:id, *FILE_SET_COLUMNS).map do |id, *file_set_values|
        [file_set_values, files_by_file_set_id.fetch(id, [])]
      end
    end

    # @return [Hash<Integer, Array<Array>>] the attributes of the files in order, by the id of their resource
    def content_files_by_file_set_id
      ContentFile.joins(:content_file_set, :content_file_binary)
                 .where(content_file_sets: { content_id: content.id })
                 .order('content_files.position')
                 .pluck(:content_file_set_id, *qualified_file_columns)
                 .group_by(&:first)
                 .transform_values { |rows| rows.map { |row| row.drop(1) } }
    end

    # Built with Contents::Builder, so that the Cocina object is mapped to attributes as for the Content.
    def cocina_structure
      Contents::Builder.build(cocina_object:).content_file_sets.map do |content_file_set|
        [content_file_set.attributes.values_at(*FILE_SET_COLUMNS),
         content_file_set.content_files.map do |content_file|
           content_file.attributes.values_at(*FILE_COLUMNS) +
             content_file.content_file_binary.attributes.values_at(*BINARY_COLUMNS)
         end]
      end
    end

    def qualified_file_columns
      FILE_COLUMNS.map { |column| "content_files.#{column}" } +
        BINARY_COLUMNS.map { |column| "content_file_binaries.#{column}" }
    end
  end
end
