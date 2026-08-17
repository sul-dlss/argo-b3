# frozen_string_literal: true

module Show
  # Component for rendering the deposit status box on the show page.
  class StatusComponent < ApplicationComponent
    STATUS_ICONS = {
      deposited: 'bi-check-circle-fill text-success',
      error: 'bi-exclamation-triangle-fill text-danger'
    }.freeze

    def initialize(document:, version_service:)
      @document = document
      @version_service = version_service
      super()
    end

    attr_reader :document, :version_service

    delegate :workflow_errors, to: :document

    def status
      return :error if workflow_errors.present?
      return :depositing if version_service.accessioning?
      return :deposited if version_service.closed?

      :draft
    end

    def heading
      label = I18n.t("show.status.#{status}.heading")
      return label unless icon_class

      safe_join([tag.i(class: "#{icon_class} me-2", aria: { hidden: true }), label], ' ')
    end

    def workflow_error_messages
      workflow_errors.map { |workflow_error| format_workflow_error(workflow_error) }
    end

    private

    def icon_class
      STATUS_ICONS[status]
    end

    # See https://github.com/sul-dlss/argo/blob/main/app/helpers/value_helper.rb#L6-L9
    def format_workflow_error(workflow_error)
      _workflow, step, message = workflow_error.split(':', 3)
      "#{step} : #{message}"
    end
  end
end
