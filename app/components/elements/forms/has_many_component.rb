# frozen_string_literal: true

module Elements
  module Forms
    # Renders a has_many association as a list of nested forms that can be added to and removed
    # from dynamically in the browser. Ported from H3's HasManyComponent.
    class HasManyComponent < ApplicationComponent
      def initialize(form:, field_name:, form_component:,
                     add_button_label: 'Add another',
                     container_classes: [])
        @form = form
        @field_name = field_name
        @form_component = form_component
        @add_button_label = add_button_label
        @container_classes = container_classes
        collection.build if collection.empty?
        super()
      end

      attr_reader :form, :field_name, :form_component, :add_button_label

      # A blank instance of the nested form class, used only to seed the client-side template row
      # (not added to the collection).
      def template_record
        association_class_name.constantize.new
      end

      def container_classes
        merge_classes(@container_classes)
      end

      private

      def collection
        form.object.public_send(field_name)
      end

      def association_class_name
        form.object.class.associations.fetch(field_name.to_s).fetch(:class_name)
      end
    end
  end
end
