# frozen_string_literal: true

module Sdr
  # Service to interact with SDR.
  class Repository
    class Error < StandardError; end
    class NotFoundResponse < Error; end

    # @param [String] druid the druid of the object
    # @return [Cocina::Models::DROWithMetadata] the returned model
    # @raise [Error] if there is an error retrieving the object
    # @raise [NotFoundResponse] if the object is not found
    def self.find(druid:)
      Dor::Services::Client.object(druid).find
    rescue Dor::Services::Client::NotFoundResponse
      raise NotFoundResponse, "Object not found: #{druid}"
    end

    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] the updated cocina object
    # @raise [Error] when an error occurs updating the object
    def self.store(cocina_object:)
      object_client = Dor::Services::Client.object(cocina_object.externalIdentifier)
      object_client.update(params: cocina_object)
    rescue Dor::Services::Client::UnexpectedResponse => e
      raise Error, "Error storing object #{cocina_object.externalIdentifier}: #{e.message}"
    end
  end
end
