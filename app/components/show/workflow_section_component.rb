# frozen_string_literal: true

module Show
  # Component for rendering a collapsible section for a workflow on the show page.
  class WorkflowSectionComponent < ApplicationComponent
    def initialize(workflow:)
      @workflow = workflow
      super()
    end

    attr_reader :workflow

    delegate :complete?, :workflow_name, to: :workflow

    def expanded?
      !complete?
    end

    def collapse_id
      "#{workflow_name.parameterize}-collapse"
    end
  end
end
