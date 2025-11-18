# frozen_string_literal: true

# Base controller for search-related actions
class SearchApplicationController < ApplicationController
  include Search::Fields

  private

  # Builds a form object of the given class, permitting parameters appropriately.
  # @param form_class [Class] The form class to instantiate
  # @param base_key [Symbol, nil] Optional base key for nested parameters
  # @return [Object] An instance of the form class
  def build_form(form_class:)
    # If this request was from a search form, it will have a 'search' scope.
    # If this request came from a generated link, it will not.
    scope = params.key?(:search) ? :search : nil
    permitted_params = params.permit(filters_for(form_class, scope:))
    attrs = scope ? permitted_params[scope] : permitted_params
    form_class.new(**attrs, debug: params[:debug])
  end

  def filters_for(form_class, scope: nil)
    filters = form_class.attribute_types.map do |name, type|
      next { name => [] } if type.instance_of?(ActiveModel::Type::Value)

      name
    end
    return { scope => filters } if scope

    filters
  end
end
