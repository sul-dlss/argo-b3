# frozen_string_literal: true

module Sdr
  # Service to interact with the administrative tags of SDR objects.
  class AdministrativeTags
    class Error < StandardError; end
    class NotFoundResponse < Error; end

    # @param [String] druid the druid of the object
    # @return [Array<String>] the object's administrative tags
    # @raise [NotFoundResponse] if the object is not found
    def self.list(druid:)
      Dor::Services::Client.object(druid).administrative_tags.list
    rescue Dor::Services::Client::NotFoundResponse
      raise NotFoundResponse, "Object not found: #{druid}"
    end

    # @param [String] druid the druid of the object
    # @param [Array<String>] tags the administrative tags to replace the object's tags with (empty removes all tags)
    # @raise [Error] if there is an error replacing the tags
    def self.replace(druid:, tags:)
      tags_client = Dor::Services::Client.object(druid).administrative_tags
      # DSA does not allow replacing tags with an empty list, so delete them one at a time.
      if tags.empty?
        tags_client.list.each { |tag| tags_client.destroy(tag:) }
      else
        tags_client.replace(tags:)
      end
    rescue Dor::Services::Client::Error => e
      raise Error, "Replacing administrative tags failed: #{e.message}"
    end
  end
end
