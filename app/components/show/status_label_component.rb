# frozen_string_literal: true

module Show
  # Component for rendering an object's deposit status label, with an icon for some statuses.
  class StatusLabelComponent < ApplicationComponent
    # @param status [Symbol] a status from ObjectStatusPresenter#status
    def initialize(status:)
      @status = status
      super()
    end

    def call
      safe_join([status_icon, I18n.t("show.status.#{status}.heading")].compact, ' ')
    end

    private

    attr_reader :status

    def status_icon
      case status
      when :deposited
        helpers.success_icon(classes: 'text-success me-2', aria: { hidden: true })
      when :error, :staging_failed
        helpers.danger_icon(classes: 'text-danger me-2', aria: { hidden: true })
      end
    end
  end
end
