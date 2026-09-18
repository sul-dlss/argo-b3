# frozen_string_literal: true

module Search
  # Component to display the current filters applied to a search
  class CurrentFiltersComponent < ViewComponent::Base
    def initialize(search_form:, pinned:, facet_labels: {})
      @search_form = search_form
      @pinned = pinned
      @facet_labels = facet_labels
      super()
    end

    attr_reader :search_form, :pinned, :facet_labels

    delegate :current_filters, :pinnable?, to: :search_form

    # Clearing the filters keeps the user in the view they are currently in.
    def clear_all_path
      url_for(search_form.class.new)
    end

    def label_for(form_field:, value:)
      facet_config = Search::Facets.find_config_by_form_field(form_field)
      facet_labels[value] if facet_config&.label_object_type
    end

    def render?
      current_filters.any?
    end
  end
end
