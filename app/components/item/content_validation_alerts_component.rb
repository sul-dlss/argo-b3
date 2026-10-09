# frozen_string_literal: true

module Item
  # Component for rendering the errors and warnings from validating the structure of a Content.
  class ContentValidationAlertsComponent < ApplicationComponent
    # @param content_validation_result [Contents::Validators::Result]
    def initialize(content_validation_result:)
      @content_validation_result = content_validation_result
      super()
    end

    delegate :errors, :warnings, to: :content_validation_result

    def render?
      errors.present? || warnings.present?
    end

    private

    attr_reader :content_validation_result
  end
end
