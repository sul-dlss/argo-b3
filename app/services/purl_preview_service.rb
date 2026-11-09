# frozen_string_literal: true

# Retrieves a purl preview for a given cocina hash.
class PurlPreviewService
  class Error < StandardError; end

  def self.call(...)
    new(...).call
  end

  # @param cocina_hash [Hash] the cocina hash to send to purl preview
  # @param constituent_of [Array<Array(String, String)>] [druid, title] of each virtual object the object is a
  #   constituent of
  def initialize(cocina_hash:, constituent_of: [])
    @cocina_hash = cocina_hash
    @constituent_of = constituent_of
  end

  # @return [String] the HTML body returned from purl preview
  def call
    response = Faraday.post("#{Settings.purl.url}/preview",
                            { cocina: preview_cocina_hash.to_json }.to_json,
                            'Content-Type' => 'application/json')
    raise Error, "Purl preview request failed: #{response.status} #{response.body}" unless response.success?

    response.body
  end

  private

  attr_reader :cocina_hash, :constituent_of

  # Adds "Appears in" related resources, as purl-fetcher does when publishing (Publish::PublicCocinaGenerator).
  def preview_cocina_hash
    return cocina_hash if constituent_of.empty?

    description = cocina_hash.fetch(:description, {})
    related_resources = Array(description[:relatedResource]) + appears_in_resources
    cocina_hash.merge(description: description.merge(relatedResource: related_resources))
  end

  def appears_in_resources
    constituent_of.map do |druid, title|
      { title: [{ value: title }], type: 'part of', purl: Cocina::Models::Mapping::Purl.for(druid:),
        displayLabel: 'Appears in' }
    end
  end
end
