# frozen_string_literal: true

module BulkActions
  # Superclass for performing an action on a single druid in a bulk action job
  # Subclasses must implement the `#perform` method.
  class BaseJobItem
    include ActionPolicy::Behaviour

    def initialize(druid:, index:, job:)
      @druid = druid
      @index = index
      @job = job
      Honeybadger.context(druid:)
    end

    delegate :log, :user, :user_id, :export_file, :close_version?, to: :job

    attr_reader :druid, :index, :job

    # Perform the action on the item.
    # Subclasses should call success! or failure! as appropriate.
    # They may also call any of the other helper methods defined below.
    def perform
      raise NotImplementedError, 'Subclasses must implement perform'
    end

    # Indicate that the action was successful.
    def success!(message: nil)
      job.success!(druid:, message:)
    end

    # Indicate that the action failed.
    def failure!(message:)
      job.failure!(druid:, message:)
    end

    def cocina_object
      @cocina_object ||= Sdr::Repository.find(druid:)
    end

    def cocina_model
      @cocina_model ||= CocinaModels::Factory.build(cocina_object)
    end

    def open_new_version_if_needed!(description:)
      return if Sdr::VersionService.open?(druid:)
      raise 'Unable to open new version' unless Sdr::VersionService.openable?(druid:)

      @cocina_object = Sdr::VersionService.open(druid:, description:, opening_user_name: user_id)
      log("Opened new version (#{description})")
    end

    def close_version_if_needed!(force: false)
      # Note that force is set for the close version job which doesn't use the close_version param.
      # Do not close version unless requested to by user (via a job parameter)
      return unless close_version? || force

      # Do not close the initial version of an object
      return if cocina_object.version == 1 && !force

      return log('Version already closed') if Sdr::VersionService.closed?(druid:)

      raise 'Unable to close version' unless Sdr::VersionService.closeable?(druid:)

      Sdr::VersionService.close(druid:)
      log('Closed version')
    end

    def check_update_ability?
      return true if allowed_to?(:update?, cocina_object, with: ObjectPolicy, context: { user: })

      failure!(message: 'Not authorized to update')
      false
    end

    def check_read_ability?
      return true if allowed_to?(:show?, cocina_object, with: ObjectPolicy, context: { user: })

      failure!(message: 'Not authorized to read')
      false
    end

    def check_object_type?(allow_dro: true, allow_collection: true, allow_admin_policy: true)
      return true if (allow_dro && cocina_object.dro?) ||
                     (allow_collection && cocina_object.collection?) ||
                     (allow_admin_policy && cocina_object.administrative_policy?)

      failure!(message: object_type_failure_message(allow_dro:, allow_collection:,
                                                    allow_admin_policy:))

      false
    end

    private

    def object_type_failure_message(allow_dro: true, allow_collection: true, allow_admin_policy: true)
      allowed_types = [].tap do |types|
        types << 'item' if allow_dro
        types << 'collection' if allow_collection
        types << 'administrative policy' if allow_admin_policy
      end

      article = allowed_types.first == 'collection' ? 'a' : 'an'
      "Not #{article} #{allowed_types.join(' or ')} (#{cocina_object.type})"
    end
  end
end
