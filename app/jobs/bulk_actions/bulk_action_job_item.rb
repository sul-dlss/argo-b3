# frozen_string_literal: true

module BulkActions
  # Super class for performing an action on a single item in a BulkActionJob.
  # Subclasses must implement the perform method.
  class BulkActionJobItem
    include ActionPolicy::Behaviour

    def initialize(druid:, index:, job:)
      @druid = druid
      @index = index
      @job = job
      Honeybadger.context(druid:)
    end

    delegate :log, :user, :export_file, :close_version?, to: :job

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

    def open_new_version_if_needed!(description:)
      return if Sdr::VersionService.open?(druid:)
      raise 'Unable to open new version' unless Sdr::VersionService.openable?(druid:)

      @cocina_object = Sdr::VersionService.open(druid:, description:, opening_user_name: user.sunetid)
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
  end
end
