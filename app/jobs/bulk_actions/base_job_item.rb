# frozen_string_literal: true

module BulkActions
  # Superclass for performing an action on a single druid in a bulk action job
  # Subclasses must implement the `#perform` method.
  class BaseJobItem
    include ActionPolicy::Behaviour

    # Raised when an object was changed but cannot be deposited; a failure to log, not to notify.
    class NotDepositedError < StandardError; end

    authorize :user
    authorize :permission_scope

    def initialize(druid:, index:, job:)
      @druid = druid
      @index = index
      @job = job
      Honeybadger.context(druid:)
    end

    delegate :log, :user, :user_id, :permission_scope, :close_version?, to: :job

    attr_reader :druid, :index, :job

    # Perform the action on the item.
    # Subclasses should call success! or failure! as appropriate.
    # They may also call any of the other helper methods defined below.
    def perform
      raise NotImplementedError, 'Subclasses must implement perform'
    end

    # Indicate that the action was successful.
    def success!(message: nil)
      job.success!(druid:, message: "Success: #{message}")
    end

    # Indicate that the action failed.
    def failure!(message:)
      job.failure!(druid:, message: "Error: #{message}")
    end

    def cocina_object
      @cocina_object ||= Sdr::Repository.find(druid:)
    end

    def cocina_model
      @cocina_model ||= CocinaModels::Factory.build(cocina_object)
    end

    # Saves the changed cocina model in an open version and deposits it if needed, recording the item's outcome.
    # @yield after opening the version, before saving (e.g., to log the changes)
    def save_model_and_deposit!(description:, success_message:, unchanged_message: 'No changes made')
      return failure!(message: invalid_model_message) unless cocina_model.valid?
      return success!(message: unchanged_message) unless cocina_model.changed?

      open_new_version_if_needed!(description:)
      yield if block_given?
      cocina_model.save!(user_name: user_id, description:)
      deposit_if_needed!
      success!(message: success_message)
    end

    def open_new_version_if_needed!(description:)
      version_service = Sdr::VersionService.new(druid:)
      return if version_service.open?
      raise 'Unable to open new version' unless version_service.openable?

      @cocina_object = version_service.open(description:, opening_user_name: user_id)
      # If the cocina model was already built from the previous cocina object, rebase it on the opened
      # cocina object so that saving does not report a version mismatch.
      @cocina_model&.refresh_cocina_object(@cocina_object)
      log("Opened new version (#{description})")
    end

    # Deposits the draft if the user asked the job to close versions, or if forced (e.g., redepositing).
    # @raise [NotDepositedError] if the draft cannot be deposited (e.g., it has unsaved changes)
    def deposit_if_needed!(force: false)
      # Note that force is set for the redeposit job, which doesn't use the close_version param.
      # Do not close version unless requested to by user (via a job parameter)
      return unless close_version? || force

      # Do not close the initial version of an object
      return if cocina_object.version == 1 && !force

      return log('Version already closed') if Sdr::VersionService.closed?(druid:)

      # A forced deposit (redeposit) saves nothing first.
      deposit!(failure_prefix: force ? 'Not deposited' : 'Saved, but not deposited')
    end

    def deposit!(failure_prefix:)
      # Re-found, since the item's change may have updated the object (e.g., its structure).
      @cocina_object = Sdr::Repository.find(druid:)
      workflow_name = Sdr::DepositDraftService.call(cocina_object:, user_name: user_id, lane_id: 'default')
      log(workflow_name ? "Started #{workflow_name}, which will close the version" : 'Closed version')
    rescue Sdr::DepositDraftService::Error => e
      raise NotDepositedError, "#{failure_prefix}: #{e.message}"
    end

    def check_update_ability?
      return true if allowed_to?(:update?, cocina_object, with: ObjectPolicy)

      failure!(message: 'Not authorized to update')
      false
    end

    def check_read_ability?
      return true if allowed_to?(:show?, cocina_object, with: ObjectPolicy)

      failure!(message: 'Not authorized to read')
      false
    end

    def check_object_type?(allow_dro: true, allow_collection: true, allow_admin_policy: true)
      return true if (allow_dro && cocina_object.dro?) ||
                     (allow_collection && cocina_object.collection?) ||
                     (allow_admin_policy && cocina_object.admin_policy?)

      failure!(message: object_type_failure_message(allow_dro:, allow_collection:,
                                                    allow_admin_policy:))

      false
    end

    private

    # Subclasses may override to add context.
    def invalid_model_message
      cocina_model.errors.full_messages.join('; ')
    end

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
