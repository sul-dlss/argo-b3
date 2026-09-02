# frozen_string_literal: true

module Show
  # Component for rendering the deposit status box on the show page.
  class StatusComponent < ApplicationComponent
    STATUS_ICONS = {
      deposited: 'bi-check-circle-fill text-success',
      error: 'bi-exclamation-triangle-fill text-danger'
    }.freeze

    def initialize(object_status_presenter:, druid:)
      @object_status_presenter = object_status_presenter
      @druid = druid
      super()
    end

    attr_reader :object_status_presenter, :druid

    delegate :status, :workflow_error_messages, to: :object_status_presenter

    def heading
      label = I18n.t("show.status.#{status}.heading")
      return label unless icon_class

      safe_join([tag.i(class: "#{icon_class} me-2", aria: { hidden: true }), label], ' ')
    end

    private

    def icon_class
      STATUS_ICONS[status]
    end
  end
end
