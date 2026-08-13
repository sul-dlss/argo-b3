# frozen_string_literal: true

# Concern to provide permitted params for forms.
module PermittedParamsConcern
  extend ActiveSupport::Concern

  class_methods do
    # Override in subclasses if needed to prevent a param from being permitted
    def immutable_attributes
      []
    end

    # Use in controllers to validate expected parameters for forms
    def permitted_params
      user_editable_attributes + nested_association_attributes
    end

    private

    def user_editable_attributes
      (attribute_names.map(&:to_sym) - immutable_attributes.map(&:to_sym)).map do |attribute_name|
        # Could not find a way to determine when attribute is an array.
        # This approach is based on the assumption that every attribute will
        # have a type EXCEPT for arrays.
        type_for_attribute(attribute_name).type.nil? ? { attribute_name => [] } : attribute_name
      end
    end

    # Associations whose target class does not include PermittedParamsConcern are not
    # user-editable via forms (e.g., associations that are structural/internal to the
    # underlying Cocina model) and are skipped.
    def nested_association_attributes
      associations.filter_map do |association_name, association|
        target_class = association[:class_name].constantize
        next unless target_class.respond_to?(:permitted_params)

        { "#{association_name}_attributes": target_class.permitted_params }
      end
    end
  end
end
