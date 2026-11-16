# frozen_string_literal: true

module Search
  # Component for toggling between the search views (search results and workflow status).
  #
  # The view is identified by the search form's class, so this links to the current search
  # as each view's form class rather than binding a form field.
  class ViewToggleComponent < ApplicationComponent
    VIEWS = [
      { form_class: ResultsSearchForm, label: 'Search results view' },
      { form_class: WorkflowGridSearchForm, label: 'Workflow status view' }
    ].freeze

    # @param search_form [SearchForm] the current search
    def initialize(search_form:)
      @search_form = search_form
      super()
    end

    attr_reader :search_form

    def call
      render SdrViewComponents::Elements::LinkToggleComponent.new(links: views, label: 'Select view', classes: 'mb-3')
    end

    # @return [Array<Hash>] one entry per view, with the label, path and selected state
    def views
      VIEWS.map do |view|
        {
          label: view[:label],
          path: url_for(search_form.as(view[:form_class])),
          selected: search_form.instance_of?(view[:form_class])
        }
      end
    end
  end
end
