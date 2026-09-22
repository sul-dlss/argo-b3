# frozen_string_literal: true

module Elements
  # Component that appends a toast for flash[:toast] to the toast container.
  # Because the toast container is permanent, appending via turbo stream.
  class FlashToastComponent < ApplicationComponent
    def call
      # Do not disappear in test env to allow for testing, but disappear in other environments.
      toast = render(SdrViewComponents::Elements::ToastComponent.new(title:, disappearing: !Rails.env.test?))
      helpers.turbo_stream.append('toast-container', toast)
    end

    def render?
      title.present?
    end

    private

    def title
      helpers.flash[:toast]
    end
  end
end
