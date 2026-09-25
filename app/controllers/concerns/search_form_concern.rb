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
  # Search forms submit unscoped (scope: '') so their params match those of generated links.
  def set_search_form
    permitted_params = params.permit(search_form_class.permitted_params)
    @search_form = search_form_class.new(**permitted_params, debug: params[:debug])
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
end
