# frozen_string_literal: true

# Concern for controllers handling facet paging.
# The controller must be a subclass of FacetsApplicationController.
module FacetPagingConcern
  extend ActiveSupport::Concern

  # Render the paging turbo-frame
  def index
    facet_counts = Searchers::Facet.call(search_form:,
                                         facet_config:,
                                         page: required_page_param)
    component = Search::FacetComponent.new(
      facet_counts:,
      search_form:,
      form_field:,
      facet_page_path_helper: facet_path_helper
    )
    render(component, content_type: 'text/html')
  end
end
