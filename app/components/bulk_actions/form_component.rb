# frozen_string_literal: true

module BulkActions
  # Component for rendering common parts of the form for a bulk action.
  class FormComponent < ApplicationComponent
    def initialize(form:, bulk_action_config:)
      @form = form
      @bulk_action_config = bulk_action_config
      super()
    end

    attr_reader :form, :bulk_action_config

    delegate :label, :help_text, to: :bulk_action_config
  end
end
