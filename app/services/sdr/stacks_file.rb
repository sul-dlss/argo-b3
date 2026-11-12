# frozen_string_literal: true

module Sdr
  # Retrieves a shelved file from stacks.
  class StacksFile
    # Raised when stacks does not provide the file, e.g., it is not shelved or the download is not permitted.
    class NotFoundError < StandardError; end

    def self.stream(druid:, filepath:, &)
      new(druid:, filepath:).stream(&)
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
    def stream(&)
      response = get(url, headers, &)
      redirect_url = redirect_url(response)
      # The redirect URL carries its own authorization, so the service token is not sent.
      response = get(redirect_url, {}, &) if redirect_url
      return if response.status == 200

      raise NotFoundError, "Stacks returned #{response.status} for #{druid} (#{filepath})"
    end

    private

    attr_reader :druid, :filepath

    # Yields the body only if the response is OK.
    def get(url, headers)
      Faraday.get(url, nil, headers) do |request|
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
