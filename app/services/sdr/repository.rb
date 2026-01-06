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

    # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
    # @param [String] description the description of the update for DSA Event
    # @param [String] user_name the sunetid of the user performing the action
    # @raise [Error] if there is an error updating the object
    # @return [Cocina::Models::DRO] the updated cocina object
    def self.update(cocina_object:, user_name:, description: nil)
      Dor::Services::Client.object(cocina_object.externalIdentifier).update(params: cocina_object,
                                                                            description:,
                                                                            user_name:)
    rescue Dor::Services::Client::Error => e
      raise Error, "Updating failed: #{e.message}"
    end

    # @param [Cocina::Models::RequestDRO] cocina_object
    # @param [String] user_name the sunetid of the user performing the action
    # @param [String] workflow_name the name of the workflow to start upon registration
    # @param [Array<String>] tags administrative tags to add upon registration
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] the registered cocina object
    # @raise [Error] if there is an error depositing the work
    def self.register(cocina_object:, user_name:, workflow_name:, tags: [])
      response_cocina_object = Dor::Services::Client.objects.register(params: cocina_object, user_name:)

      object_client = Dor::Services::Client.object(response_cocina_object.externalIdentifier)

      # NOTE: Create administrative tags before the workflow is created, else workflows
      #       that rely on admin tags (e.g., `goobiWF`) could sporadically fail.
      object_client.administrative_tags.create(tags:) unless tags.empty?

      object_client.workflow(workflow_name).create(version: '1')

      response_cocina_object
    rescue Dor::Services::Client::Error => e
      raise Error, "Registration failed: #{e.message}"
    end
  end
end
