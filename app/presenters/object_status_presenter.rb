# frozen_string_literal: true

# Presenter for determining the deposit status of an object.
class ObjectStatusPresenter
  def initialize(document:, version_service:, content:)
    @document = document
    @version_service = version_service
    @content = content
  end

  delegate :workflow_errors, :druid, to: :document

  def status
    # For the purposes of the status, treating these states as mutually exclusive.
    # However, they are not logically exclusive, e.g., an object that is staging
    # is in draft.
    # Thus, the order of these statements is potentially significant.
    return :staging if content&.staging?
    return :staging_failed if content&.staging_failed?
    return :error if workflow_errors.present?

    version_status
  end

  def workflow_error_messages
    workflow_errors.map { |workflow_error| format_workflow_error(workflow_error) }
  end

  private

  attr_reader :document, :version_service, :content

  def version_status
    return :assembling if version_service.assembling?
    return :depositing if version_service.accessioning?
    return :deposited if version_service.closed?

    :draft
  end

  # See https://github.com/sul-dlss/argo/blob/main/app/helpers/value_helper.rb#L6-L9
  def format_workflow_error(workflow_error)
    _workflow, step, message = workflow_error.split(':', 3)
    "#{step} : #{message}"
  end
end
