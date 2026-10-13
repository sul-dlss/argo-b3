# frozen_string_literal: true

module Elements
  # Component that appends a toast to the toast container, for the given title or else flash[:toast].
  # Because the toast container is permanent, appending via turbo stream.
  class FlashToastComponent < ApplicationComponent
    def initialize(title: nil)
      @title = title
      super()
    end

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
      @title || helpers.flash[:toast]
    end
  end
end
