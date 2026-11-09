# frozen_string_literal: true

module Show
  # Component for rendering a row of a workflow table on the show page.
  class WorkflowProcessRowComponent < ApplicationComponent
    # @param actions [Boolean] whether to include the actions cell
    def initialize(process:, solr_doc:, actions:)
      @process = process
      @solr_doc = solr_doc
      @actions = actions
      super()
    end

    attr_reader :process, :solr_doc

    delegate :name, :lifecycle, :status, :datetime, :elapsed, :error_message, :note, to: :process

    def actions?
      @actions
    end

    def error?
      status == 'error'
    end
  end
end
