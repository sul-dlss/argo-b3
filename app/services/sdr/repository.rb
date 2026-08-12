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

    # Retrieve the "live" solr document for the object.
    # It is recreated for the current DSA data; it is not the solr document stored in Solr.
    # @param [String] druid the druid of the object
    # @return [Hash] the Solr document
    # @raise [Error] if there is an error retrieving the object
    # @raise [NotFoundResponse] if the object is not found
    def self.find_solr(druid:)
      Dor::Services::Client.object(druid).solr(validate: false)
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

    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy]
    #   request_cocina_object
    # @param [String] user_name the sunetid of the user performing the action
    # @param [String] workflow_name the name of the workflow to start upon registration, if any
    # @param [Array<String>] tags administrative tags to add upon registration
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] the registered cocina object
    # @raise [Error] if there is an error depositing the work
    def self.register(request_cocina_object:, user_name:, workflow_name: nil, tags: [])
      response_cocina_object = Dor::Services::Client.objects.register(params: request_cocina_object, user_name:)

      object_client = Dor::Services::Client.object(response_cocina_object.externalIdentifier)

      # NOTE: Create administrative tags before the workflow is created, else workflows
      #       that rely on admin tags (e.g., `goobiWF`) could sporadically fail.
      object_client.administrative_tags.create(tags:) unless tags.empty?

      object_client.workflow(workflow_name).create(version: '1') if workflow_name

      response_cocina_object
    rescue Dor::Services::Client::Error => e
      raise Error, "Registration failed: #{e.message}"
    end

    # @param [String] druid the druid of the object
    # @param [String] user_name the sunetid of the user performing the action
    # @param [String,nil] version_description the description of the version or nil to leave unchanged
    # @param [String] lane_id the lane to use for accessioning, defaults to 'high'
    # @raise [Error] if there is an error initiating accession
    def self.accession(druid:, user_name:, version_description: nil, lane_id: 'high')
      # Close the version, which will also start accessioning
      Dor::Services::Client.object(druid)
                           .version.close(user_name:,
                                          description: version_description,
                                          lane_id:)
    rescue Dor::Services::Client::Error => e
      raise Error, "Initiating accession failed: #{e.message}"
    end

    # @param [String] druid the druid of the object
    # @param [String] user_name the sunetid of the user performing the action
    # @param [String] release_target Searchworks, Earthworks, or PURL sitemap
    # @param [Boolean] release false to not release the object
    # @param [String] release_what self or collection
    # @param [String] lane_id lane to using for releaseWF (high, default, or low) if object has been published
    def self.create_release_tag(druid:, user_name:, release_target:, release:, release_what: 'self', lane_id: 'high') # rubocop:disable Metrics/ParameterLists
      new_tag = Dor::Services::Client::ReleaseTag.new(
        **{ to: release_target }.compact, # "to" must be omitted when nil.
        who: user_name,
        what: release_what,
        release:,
        date: DateTime.now.utc.iso8601
      )
      Dor::Services::Client.object(druid).release_tags.create(tag: new_tag, lane_id:)
    rescue Dor::Services::Client::Error => e
      raise Error, "Creating release tag failed: #{e.message}"
    end
  end
end
