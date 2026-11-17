# frozen_string_literal: true

require 'faraday/retry'

module Sdr
  # Retrieves a shelved file from stacks.
  class StacksFile
    # Raised when stacks fails (a 5xx response).
    class Error < StandardError; end

    # Raised when stacks does not provide the file, e.g., it is not shelved or the download is not permitted.
    class NotFoundError < Error; end

    RETRY_OPTIONS = {
      max: 2,
      interval: 5,
      backoff_factor: 2,
      exceptions: [*Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS, Faraday::ConnectionFailed],
      retry_statuses: [500, 502, 503, 504]
    }.freeze

    def self.stream(druid:, filepath:, &)
      new(druid:, filepath:).stream(&)
    end

    def self.to_file(druid:, filepath:, destination:)
      new(druid:, filepath:).to_file(destination:)
    end

    # @param [String] druid the druid of the object
    # @param [String] filepath the path of the file within the object
    def initialize(druid:, filepath:)
      @druid = druid
      @filepath = filepath
    end

    # Streams the file, raising before yielding any data if stacks does not provide it.
    # Follows a redirect to another host (e.g., a signed S3 URL), but not within stacks (e.g., to log in).
    # @yieldparam [String] chunk of the file
    # @raise [NotFoundError] if stacks does not provide the file
    # @raise [Error] if stacks fails
    def stream(&)
      download(Faraday.new, &)
    end

    # Writes the file to the destination, retrying failed requests.
    # @param [String] destination path of the file to write
    # @raise [NotFoundError] if stacks does not provide the file
    # @raise [Error] if stacks fails
    def to_file(destination:)
      File.open(destination, 'wb') do |file|
        # A retry restarts the download, so the partly written file is discarded.
        connection = Faraday.new do |builder|
          builder.request :retry, **RETRY_OPTIONS, retry_block: proc {
            file.truncate(0)
            file.rewind
          }
        end
        download(connection) { |chunk| file.write(chunk) }
      end
    end

    private

    attr_reader :druid, :filepath

    def download(connection, &)
      response = get(connection, url, headers, &)
      redirect_url = redirect_url(response)
      # The redirect URL carries its own authorization, so the service token is not sent.
      response = get(connection, redirect_url, {}, &) if redirect_url
      return if response.status == 200

      error_class = response.status >= 500 ? Error : NotFoundError
      raise error_class, "Stacks returned #{response.status} for #{druid} (#{filepath})"
    end

    # Yields the body only if the response is OK.
    def get(connection, url, headers)
      connection.get(url, nil, headers) do |request|
        request.options.on_data = proc do |chunk, _size, env|
          yield chunk if env.status == 200
        end
      end
    end

    # @return [String, nil] the redirect location, if it is on another host
    def redirect_url(response)
      return unless response.status.between?(300, 399) && response.headers['Location'].present?

      location = URI.join(url, response.headers['Location'])
      location.to_s unless location.host == URI(url).host
    end

    # The service token downloads with the access of a Stanford user.
    def headers
      Settings.stacks.token.present? ? { 'Authorization' => "Bearer #{Settings.stacks.token}" } : {}
    end

    def url
      @url ||= begin
        encoded_filepath = filepath.split('/').map { |part| ERB::Util.url_encode(part) }.join('/')
        "#{Settings.stacks.file_url}/#{druid}/#{encoded_filepath}"
      end
    end
  end
end
