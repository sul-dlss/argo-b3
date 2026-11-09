# frozen_string_literal: true

module Search
  # Component for toggling between the search views (search results and workflow status).
  #
  # Switching views is navigation, not data entry, so this renders links rather than a radio group.
  # The markup mirrors SdrViewComponents::Forms::ToggleComponent, but that component renders
  # form.radio_button and so requires the form to have a `view` attribute; a form's class is what
  # identifies its view, so there is deliberately no such attribute. The component library's
  # .toggle-radio styles apply to the links, with .active in place of :checked; see .view-toggle in
  # search.scss for what links need beyond that.
  class ViewToggleComponent < ViewComponent::Base
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

    # @return [Array<Hash>] one entry per view, with the label, path and selected state
    def views
      VIEWS.map do |view|
        view.merge(
          path: url_for(search_form.as(view[:form_class])),
          selected: search_form.instance_of?(view[:form_class])
        )
      end
    end
  end
end
