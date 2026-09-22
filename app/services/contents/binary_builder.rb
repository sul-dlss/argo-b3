# frozen_string_literal: true

module Contents
  # Builds the ContentFileBinaries for an existing Content from uploaded files, attaching each
  # uploaded binary. Files that should be ignored are skipped and never become records.
  # Structuring the binaries into ContentFileSets and ContentFiles is left to the Contents::Populators.
  class BinaryBuilder
    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    # @param [Hash] files uploaded files keyed by their upload index
    # @param [Hash] paths full filepaths keyed by their upload index
    def initialize(content:, files:, paths:)
      @content = content
      @files = files
      @paths = paths
    end

    def call
      files.each do |index, file|
        filepath = paths[index]
        next if filepath.blank? || IgnoreFileService.call(filepath:)

        build_content_file_binary(filepath:, file:)
      end
    end

    private

    attr_reader :content, :files, :paths

    def build_content_file_binary(filepath:, file:)
      content_file_binary = find_or_build_content_file_binary(filepath:)
      attach_file(content_file_binary:, file:)
    end

    def find_or_build_content_file_binary(filepath:)
      content.content_file_binaries.find_by(filepath:) ||
        content.content_file_binaries.build(filepath:)
    end

    def attach_file(content_file_binary:, file:)
      content_file_binary.file_location = :attached
      content_file_binary.size = file.size
      content_file_binary.sha1_digest = nil
      content_file_binary.md5_digest = nil
      content_file_binary.save!
      content_file_binary.file.attach(file)
    end
  end
end
