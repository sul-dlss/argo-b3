# frozen_string_literal: true

# Presenter for determining the deposit status of an object.
class ObjectStatusPresenter
  def initialize(document:, version_service:, content:)
    @document = document
    @version_service = version_service
    @content = content
  end

  delegate :workflow_errors, to: :document

  def status
    # For the purposes of the status, treating these states as mutually exclusive.
    # However, they are not logically exclusive, e.g., an object that is staging
    # is in draft.
    # Thus, the order of these statements is potentially significant.
    return :staging if content&.staging?
    return :error if workflow_errors.present?
    return :depositing if version_service.accessioning?
    return :deposited if version_service.closed?

    :draft
  end

  def workflow_error_messages
    workflow_errors.map { |workflow_error| format_workflow_error(workflow_error) }
  end

  private

  attr_reader :document, :version_service, :content

  # See https://github.com/sul-dlss/argo/blob/main/app/helpers/value_helper.rb#L6-L9
  def format_workflow_error(workflow_error)
    _workflow, step, message = workflow_error.split(':', 3)
    "#{step} : #{message}"
  end
end
