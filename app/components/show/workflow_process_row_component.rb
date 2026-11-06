# frozen_string_literal: true

module Show
  # Component for rendering a row of a workflow table on the show page.
  class WorkflowProcessRowComponent < ApplicationComponent
    def initialize(process:)
      @process = process
      super()
    end

    attr_reader :process

    delegate :name, :lifecycle, :status, :datetime, :elapsed, :error_message, :note, to: :process

    def error?
      status == 'error'
    end
  end
end
