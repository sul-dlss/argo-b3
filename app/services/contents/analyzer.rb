# frozen_string_literal: true

module Contents
  # Adds MD5, SHA1, size, and mime type to a ContentFileBinary.
  class Analyzer
    def self.call(...)
      new(...).call
    end

    # @param [ContentFileBinary] content_file_binary
    # @param [Boolean] mime_type_only when true, only populate the mime type, skipping the digests and size
    def initialize(content_file_binary:, mime_type_only: false)
      @content_file_binary = content_file_binary
      @mime_type_only = mime_type_only
    end

    def call
      update_mime_type
      unless mime_type_only
        update_digests
        update_size
      end
      content_file_binary.save!
    end

    private

    attr_reader :content_file_binary, :mime_type_only

    # The attached blob's content type is ignored since it is influenced by the browser.
    def update_mime_type
      return if content_file_binary.mime_type.present?

      content_file_binary.mime_type = MimeTypeSupport.for(path: content_file_binary.filepath_on_disk,
                                                          filepath: content_file_binary.filepath)
    end

    def update_digests # rubocop:disable Metrics/AbcSize
      return if content_file_binary.md5_digest.present? && content_file_binary.sha1_digest.present?

      md5 = Digest::MD5.new
      sha1 = Digest::SHA1.new

      File.open(content_file_binary.filepath_on_disk) do |stream|
        while (buffer = stream.read(4096))
          md5.update(buffer)
          sha1.update(buffer)
        end
      end
      content_file_binary.md5_digest = md5.hexdigest
      content_file_binary.sha1_digest = sha1.hexdigest
    end

    def update_size
      return if content_file_binary.size.present?

      content_file_binary.size = if content_file_binary.file_location_attached?
                                   content_file_binary.file.blob.byte_size
                                 else
                                   File.size(content_file_binary.filepath_on_disk)
                                 end
    end
  end
end
