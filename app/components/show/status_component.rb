# frozen_string_literal: true

module Show
  # Component for rendering the deposit status box on the show page.
  class StatusComponent < ApplicationComponent
    def initialize(object_status_presenter:)
      @object_status_presenter = object_status_presenter
      super()
    end

    attr_reader :object_status_presenter

    delegate :status, :workflow_error_messages, :druid, to: :object_status_presenter

    def heading
      label = I18n.t("show.status.#{status}.heading")
      icon_tag = status_icon
      return label if icon_tag.nil?

      safe_join([icon_tag, label], ' ')
    end

    private

    def status_icon
      case status
      when :deposited
        helpers.success_icon(classes: 'text-success me-2', aria: { hidden: true })
      when :error
        helpers.danger_icon(classes: 'text-danger me-2', aria: { hidden: true })
      end
    end
  end
end
