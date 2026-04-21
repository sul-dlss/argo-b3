# frozen_string_literal: true

# Retrieves a purl preview for a given cocina hash.
class PurlPreviewService
  class Error < StandardError; end

  def self.call(...)
    new(...).call
  end

  # @param cocina_hash [Hash] the cocina hash to send to purl preview
  def initialize(cocina_hash:)
    @cocina_hash = cocina_hash
  end

  # @return [String] the HTML body returned from purl preview
  def call
    response = Faraday.post("#{Settings.purl.url}/preview",
                            { cocina: cocina_hash.to_json }.to_json,
                            'Content-Type' => 'application/json')
    raise Error, "Purl preview request failed: #{response.status} #{response.body}" unless response.success?

    response.body
  end

  private

  attr_reader :cocina_hash
end
