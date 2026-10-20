# frozen_string_literal: true

module Contents
  # Records the files in a directory on the mount as ContentFileBinaries for a Content.
  # Files that should be ignored are skipped and never become records.
  class MountDiscoverer
    # Raised before any binaries are built when discovered filepaths contain invalid UTF-8 bytes.
    class InvalidFilepathsError < StandardError; end

    def self.call(...)
      new(...).call
    end

    # @param mount_path [String] the directory on the mount
    # @return [Array<String>] the filepaths (relative to the mount path) of the files that are not ignored
    def self.filepaths(mount_path:)
      # File::FNM_DOTMATCH matches .<filename> files.
      filepaths = Dir.glob('**/*', File::FNM_DOTMATCH, base: mount_path)
                     .select { |filepath| File.file?(File.join(mount_path, filepath)) }
                     .reject { |filepath| IgnoreFileService.call(filepath:) }
      invalid_filepaths = filepaths.reject { |filepath| filepath.dup.force_encoding(Encoding::UTF_8).valid_encoding? }
      if invalid_filepaths.any?
        raise InvalidFilepathsError,
              "Filepaths contain invalid UTF-8 bytes: #{invalid_filepaths.map(&:inspect).join(', ')}"
      end

      filepaths
    end

    # @param content [Content]
    # @param mount_path [String] the directory on the mount to discover files in (recursively)
    def initialize(content:, mount_path:)
      @content = content
      @mount_path = mount_path
    end

    def call
      self.class.filepaths(mount_path:).each { |filepath| build_content_file_binary(filepath:) }
    end

    private

    attr_reader :content, :mount_path

    def build_content_file_binary(filepath:) # rubocop:disable Metrics/AbcSize
      content_file_binary = content.content_file_binaries.find_or_initialize_by(filepath:)
      full_filepath = File.join(mount_path, filepath)
      content_file_binary.file_location = :mount
      content_file_binary.mount_path = mount_path
      content_file_binary.size = File.size(full_filepath)
      content_file_binary.mime_type = Marcel::MimeType.for(Pathname.new(full_filepath), name: filepath)
      content_file_binary.sha1_digest = nil
      content_file_binary.md5_digest = nil
      content_file_binary.save!
    end
  end
end
