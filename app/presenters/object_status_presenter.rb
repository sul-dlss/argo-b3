# frozen_string_literal: true

# Presenter for determining the deposit status of an object.
class ObjectStatusPresenter
  # @param initiating [Boolean] true if the object's deposit is being initiated but has not yet started staging
  def initialize(document:, version_service:, content:, initiating: false)
    @document = document
    @version_service = version_service
    @content = content
    @initiating = initiating
  end

  delegate :workflow_errors, :druid, :bare_druid, to: :document

  def status
    # For the purposes of the status, treating these states as mutually exclusive.
    # However, they are not logically exclusive, e.g., an object that is staging
    # is in draft.
    # Thus, the order of these statements is potentially significant.
    return :staging if content&.staging?
    return :staging_failed if content&.staging_failed?
    return :initiating if initiating
    return :error if workflow_errors.present?

    version_status
  end

  # @return [Boolean] true if the object's version can be opened or closed
  def version_editable?
    version_service.editable?
  end

  def workflow_error_messages
    workflow_errors.map { |workflow_error| format_workflow_error(workflow_error) }
  end

  private

  attr_reader :document, :version_service, :content, :initiating

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
