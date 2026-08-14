# frozen_string_literal: true

module Show
  # Component for rendering the deposit status box on the show page.
  class StatusComponent < ApplicationComponent
    def initialize(document:)
      @document = document
      super()
    end

    attr_reader :document

    delegate :workflow_errors, to: :document

    def status
      return :error if workflow_errors.present?
      return :depositing if version_service.accessioning?
      return :deposited if version_service.closed?

      :draft
    end

    def heading
      I18n.t("show.status.#{status}.heading")
    end

    def workflow_error_messages
      workflow_errors.map { |workflow_error| format_workflow_error(workflow_error) }
    end

    private

    # See https://github.com/sul-dlss/argo/blob/main/app/helpers/value_helper.rb#L6-L9
    def format_workflow_error(workflow_error)
      _workflow, step, message = workflow_error.split(':', 3)
      "#{step} : #{message}"
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid: document.druid)
    end
  end
end
