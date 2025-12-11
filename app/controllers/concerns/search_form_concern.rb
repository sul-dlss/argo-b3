# frozen_string_literal: true

# Concern for controllers that need to build a search form.
module SearchFormConcern
  extend ActiveSupport::Concern

  # Builds a SearchForm permitting parameters appropriately.
  def set_search_form
    # If this request was from a search form, it will have a 'search' scope.
    # If this request came from a generated link, it will not.
    scope = params.key?(:search) ? :search : nil
    permitted_params = params.permit(filters_for(scope:))
    attrs = scope ? permitted_params[scope] : permitted_params
    @search_form = SearchForm.new(**attrs, debug: params[:debug])
  end

  def filters_for(scope: nil)
    filters = SearchForm.attribute_types.map do |name, type|
      next { name => [] } if type.instance_of?(ActiveModel::Type::Value)

      name
    end
    return { scope => filters } if scope

    filters
  end
end
