# frozen_string_literal: true

# Helpers for determining mime types.
class MimeTypeSupport
  # Marcel's default: the file's content, falling back to the filepath's extension; never a declared type.
  # @param path [String] the location of the file on disk
  # @param filepath [String] the file's filepath within the object
  # @return [String] the mime type
  def self.for(path:, filepath:)
    Marcel::MimeType.for(Pathname.new(path), name: filepath)
  end
end
