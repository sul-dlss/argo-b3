# frozen_string_literal: true

module Dashboard
  # Component for displaying a dismissible informational banner on the dashboard.
  class BannerComponent < ApplicationComponent
    def initialize(text:, variant: :info, dismissible: true)
      @text = text
      @variant = variant
      @dismissible = dismissible
      super()
    end

    attr_reader :text, :variant, :dismissible

    def render?
      text.present?
    end
  end
end
