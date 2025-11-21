# frozen_string_literal: true

module Search
  # Form for searching items (DROs, collections, or APOs)
  class ItemForm < Search::Form
    attribute :object_types, array: true, default: -> { [] }
    attribute :projects, array: true, default: -> { [] }
    attribute :tags, array: true, default: -> { [] }
    attribute :access_rights, array: true, default: -> { [] }
    attribute :wps_workflows, array: true, default: -> { [] }
    attribute :mimetypes, array: true, default: -> { [] }

    # @return [Hash] attributes defined on this class (not its superclasses)
    def this_attributes
      attributes.slice(*self.class.this_attribute_names)
    end

    delegate :this_attribute_names, to: :class

    # @return [Array<Array(String, String)>] current filters as attribute name/value pairs
    def current_filters
      self.class.this_attribute_names.flat_map do |attr_name|
        values = public_send(attr_name)
        Array(values).map do |value|
          [attr_name, value]
        end
      end
    end

    class << self
      # @return [Array<String>] attribute names defined on this class (not its superclasses)
      def this_attribute_names
        attribute_names - superclass.attribute_names
      end
    end
  end
end
