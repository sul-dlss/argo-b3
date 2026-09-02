# frozen_string_literal: true

module Contents
  # Creates ContentFile records and attaches uploaded binaries to a Content.
  class FileUpdater
    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    # @param [Cocina::Models::DROWithMetadata] cocina_object
    # @param [Hash] files uploaded files keyed by their upload index
    # @param [Hash] paths full filepaths keyed by their upload index
    def initialize(content:, cocina_object:, files:, paths:)
      @content = content
      @cocina_object = cocina_object
      @files = files
      @paths = paths
    end

    def call
      files.each do |index, file|
        filepath = paths[index]
        next if IgnoreFileService.call(filepath:)

        create_content_file(filepath:, file:)
      end
    end

    private

    attr_reader :content, :cocina_object, :files, :paths

    # Current naive implementation is one FileSet per file.
    def create_content_file(filepath:, file:)
      content_file_set = content.content_file_sets.create!(file_set_type: 'object', label: '')
      content_file_binary = find_or_build_content_file_binary(filepath:)
      attach_file(content_file_binary:, file:)
      content_file_set.content_files.create!(content_file_binary:, **file_attributes)
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

    def file_attributes
      access = cocina_object.access.embargo.presence || cocina_object.access
      {
        label: '',
        preserve: true,
        publish: true,
        shelve: true,
        view: access.view == 'citation-only' ? 'dark' : access.view,
        download: access.download,
        location: access.location
      }
    end
  end
end
