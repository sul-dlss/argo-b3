# frozen_string_literal: true

# A Rack body that streams a file of an object from its staged files, preservation, or stacks (the first that has it).
class FileDownloadService
  # Raised, before any data is written, if no source has the file.
  class NotFoundError < StandardError; end

  CHUNK_SIZE = 1.megabyte

  # @param [String] druid the druid of the object
  # @param [String] filepath the path of the file within the object
  def initialize(druid:, filepath:)
    @druid = druid
    @filepath = filepath
    @staged_filepath = StagingSupport.find_staged_filepath(druid:, filepath:)
  end

  # @return [Hash] the Content-Length header, if the size of the file is known
  def headers
    { 'Content-Length' => size&.to_s }.compact
  end

  # A Rack streaming body; the server has written the headers and hands over the connection.
  # On error, closing leaves the download short of its Content-Length, so the browser fails it. Raising would let
  # Puma write an error response into the file.
  # @param [IO] stream the connection to the client
  def call(stream)
    each_chunk { |chunk| stream.write(chunk) }
  rescue IOError, SystemCallError
    nil # The client disconnected.
  rescue NotFoundError => e
    # Expected while the object is accessioning, so logged but not reported.
    Rails.logger.warn("File download of #{filepath} for #{druid} not available: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("File download of #{filepath} for #{druid} failed: #{e.class}: #{e.message}")
    Rails.error.report(e)
  ensure
    stream.close
  end

  private

  attr_reader :druid, :filepath, :staged_filepath

  def size
    return File.size(staged_filepath) if staged_filepath

    # The newest immutable Content is the one shown on the object page that linked here.
    ContentFileBinary.joins(:content).where(filepath:, contents: { druid:, immutable: true })
                     .order(Content.arel_table[:id].desc).pick(:size)
  end

  def each_chunk(&)
    return stream_staged_file(&) if staged_filepath

    stream_preserved_file(&)
  rescue Preservation::Client::NotFoundError
    stream_stacks_file(&)
  end

  def stream_staged_file
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
