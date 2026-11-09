# frozen_string_literal: true

module Show
  # Component for rendering a collapsible section for a workflow on the show page.
  class WorkflowSectionComponent < ApplicationComponent
    # @param solr_doc [SolrDocPresenter] the object, for authorizing process actions
    def initialize(workflow:, solr_doc:)
      @workflow = workflow
      @solr_doc = solr_doc
      super()
    end

    attr_reader :workflow, :solr_doc

    delegate :complete?, :workflow_name, to: :workflow

    def expanded?
      !complete?
    end

    def collapse_id
      "#{workflow_name.parameterize}-collapse"
    end
  end
end
