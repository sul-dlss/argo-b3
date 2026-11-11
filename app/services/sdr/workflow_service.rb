# frozen_string_literal: true

module Sdr
  # Service for interacting with the workflows.
  class WorkflowService
    # @return [Array<Dor::Services::Response::Workflow>] the summary of the workflows sorted by workflow name
    def self.workflows_for(druid:)
      Dor::Services::Client.object(druid).workflows.workflows.sort_by(&:workflow_name)
    end

    # The workflows whose incomplete processes keep a version from closing (DSA's Workflow::StateBatchService).
    ASSEMBLY_WORKFLOW_NAMES = %w[assemblyWF gisAssemblyWF wasSeedPreassemblyWF wasCrawlPreassemblyWF ocrWF
                                 speechToTextWF].freeze

    # @return [Boolean] true if an assembly workflow has a process in error for the version and no process of any
    #   workflow is queued or started for it, so nothing will run until a process is retried
    def self.assembly_stopped_with_error?(druid:, version:)
      processes = Dor::Services::Client.object(druid).workflows.workflows.flat_map(&:processes)
                                       .select { |process| process.version == version }
      processes.any? { |process| process.status == 'error' && process.workflow_name.in?(ASSEMBLY_WORKFLOW_NAMES) } &&
        processes.none? { |process| process.status.in?(%w[queued started]) }
    end

    PROCESS_NOTES = { 'skipped' => 'Skipped by', 'completed' => 'Completed by' }.freeze

    # Changes the status of a process in error, noting who skipped or completed it.
    # @raise [Dor::Services::Client::ConflictResponse] if the process is no longer in error
    def self.update_process(druid:, workflow_name:, process:, version:, status:, sunetid:) # rubocop:disable Metrics/ParameterLists
      note = ("#{PROCESS_NOTES[status]} #{sunetid}" if PROCESS_NOTES.key?(status))
      Dor::Services::Client.object(druid).workflow(workflow_name).process(process)
                           .update(status:, note:, version:, current_status: 'error')
    end

    # @return [Boolean] if the object has been submitted or not before
    def self.submitted?(druid:)
      return true if Dor::Services::Client.object(druid).milestones.date(milestone_name: 'submitted')

      false
    end

    # @return [Boolean] if the object has been published or not before
    def self.published?(druid:)
      return true if Dor::Services::Client.object(druid).milestones.date(milestone_name: 'published')

      false
    end

    # @return [Boolean] if the object has been accessioned or not before
    def self.accessioned?(druid:)
      return true if Dor::Services::Client.object(druid).milestones.date(milestone_name: 'accessioned')

      false
    end

    # @return [Array<Hash>] the milestones (milestone:, at:, version:) for all versions of the object
    def self.milestones(druid:)
      Dor::Services::Client.object(druid).milestones.list
    end

    # Fetches the workflow from the workflow service and checks to see if it's active
    # @return [Boolean] if the object has an active workflow
    def self.workflow_active?(druid:, version:, wf_name:)
      Dor::Services::Client.object(druid).workflow(wf_name).find.active_for?(version:)
    end
  end
end
