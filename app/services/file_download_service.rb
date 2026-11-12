# frozen_string_literal: true

# Streams a file of an object from its staged files, preservation, or stacks (the first that has it).
class FileDownloadService
  # Raised, before any data is yielded, when no source has the file.
  class NotFoundError < StandardError; end

  CHUNK_SIZE = 1.megabyte

  def self.stream(druid:, filepath:, &)
    new(druid:, filepath:).stream(&)
  end

  # @param [String] druid the druid of the object
  # @param [String] filepath the path of the file within the object
  def initialize(druid:, filepath:)
    @druid = druid
    @filepath = filepath
  end

  # @yieldparam [String] chunk of the file
  # @raise [NotFoundError] if no source has the file
  def stream(&)
    staged_filepath = StagingSupport.find_staged_filepath(druid:, filepath:)
    return stream_staged_file(staged_filepath, &) if staged_filepath

    stream_preserved_file(&)
  rescue Preservation::Client::NotFoundError
    stream_stacks_file(&)
  end

  private

  attr_reader :druid, :filepath

  def stream_staged_file(staged_filepath)
    File.open(staged_filepath, 'rb') do |file|
      while (chunk = file.read(CHUNK_SIZE))
        yield chunk
      end
    end
  end

  def stream_preserved_file
    Preservation::Client.objects.content(druid:, filepath:, on_data: proc { |data, _count| yield data })
  end

  def stream_stacks_file(&)
    Sdr::StacksFile.stream(druid:, filepath:, &)
  rescue Sdr::StacksFile::NotFoundError => e
    raise NotFoundError, e.message
  end
end
