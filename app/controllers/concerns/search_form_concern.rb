# frozen_string_literal: true

# Concern for controllers that need to build a search form.
module SearchFormConcern
  extend ActiveSupport::Concern

  # Note that /search and /workflow_grid each get a view_form root default added
  # in as part of the route configuration.
  # scope defaults: { view_form: 'results' } do
  #   resource :search, only: [:show], controller: 'search' do
  #     concerns :search_endpoints
  #   end
  # end

  # Maps the view_form route default to a search form class.
  SEARCH_FORM_CLASSES = {
    'results' => ResultsSearchForm,
    'workflow_grid' => WorkflowGridSearchForm
  }.freeze

  class UnknownViewFormError < StandardError; end

  # Builds a search form permitting parameters appropriately.
  def set_search_form
    # If this request was from a search form, it will have a 'search' scope.
    # If this request came from a generated link, it will not.
    scope = params.key?(:search) ? :search : nil
    permitted_params = params.permit(filters_for(scope:))
    attrs = scope ? permitted_params[scope] : permitted_params
    @search_form = search_form_class.new(**attrs, debug: params[:debug])
  end

  # The search form class for this request, determined by the route's view_form default.
  # @raise [UnknownViewFormError] if the route does not declare a recognized view_form
  def search_form_class
    SEARCH_FORM_CLASSES.fetch(params[:view_form]) do
      raise UnknownViewFormError,
            "route #{request.path} does not declare a known view_form (got #{params[:view_form].inspect}); " \
            'add a `scope defaults: { view_form: ... }` around the route'
    end
  end

  def filters_for(scope: nil)
    filters = search_form_class.permitted_params
    return { scope => filters } if scope

    filters
  end
end
