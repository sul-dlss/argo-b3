# frozen_string_literal: true

module Show
  # Component for rendering an accordion item for a workflow on the show page.
  class WorkflowAccordionItemComponent < ApplicationComponent
    def initialize(workflow:)
      @workflow = workflow
      super()
    end

    attr_reader :workflow

    delegate :complete?, :workflow_name, to: :workflow

    def expanded?
      !complete?
    end

    def accordion_collapse_id
      "#{workflow.workflow_name.parameterize}-collapse"
    end

    def button_classes
      merge_classes('accordion-button', expanded? ? nil : 'collapsed')
    end

    def accordion_collapse_classes
      merge_classes('accordion-collapse', 'collapse', expanded? ? 'show' : nil)
    end
  end
end
