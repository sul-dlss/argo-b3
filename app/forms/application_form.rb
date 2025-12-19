# frozen_string_literal: true

class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  class << self
    # Override in subclasses if needed to prevent a param from being permitted
    def immutable_attributes
      []
    end

    # Use in controllers to validate expected parameters for forms
    def permitted_params
      user_editable_attributes.tap do |attrs|
        attrs << nested_attributes if defined?(nested_attributes)
      end
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
  end
end
