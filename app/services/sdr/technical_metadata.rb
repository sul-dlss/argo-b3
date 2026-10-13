# frozen_string_literal: true

module Sdr
  # Retrieves technical metadata from the Technical Metadata Service
  class TechnicalMetadata
    class Error < StandardError; end

    # @param [String] druid the druid of the object
    # @param [String] filepath the path of the file within the object (the techmd filename)
    # @return [Hash, nil] technical metadata for the file (a DroFile per the techmd OpenAPI spec); nil if not found
    # @raise [Error] if the service returns an unexpected response
    def self.find(druid:, filepath:)
      response = get_for_file(druid:, filepath:)
      return if response.status == 404
      unless response.status == 200
        raise Error,
              "Unexpected response (#{response.status}) from technical-metadata-service " \
              "for #{druid} (#{filepath}): #{response.body}"
      end

      JSON.parse(response.body)
    end

    # @param [String] druid the druid of the object
    # @param [String] filepath the path of the file within the object (the techmd filename)
    # @return [Faraday::Response] response containing technical metadata for the file
    def self.get_for_file(druid:, filepath:)
      # Faraday percent-encodes the filename once (including + as %2B), as required by the service.
      Faraday.get("#{Settings.tech_md_service.url}/v1/technical-metadata/druid/#{druid}/file",
                  { filename: filepath }) do |request|
        request.headers['Accept'] = 'application/json'
        request.headers['Authorization'] = "Bearer #{Settings.tech_md_service.token}"
      end
    end
    private_class_method :get_for_file
  end
end
