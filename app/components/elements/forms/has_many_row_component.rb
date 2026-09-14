# frozen_string_literal: true

module Elements
  module Forms
    # Renders a single row of a has_many association: the nested form fields plus a button to
    # remove the row. The row markup is the contract with the has-many Stimulus controller
    # (see app/javascript/controllers/has_many_controller.js), so all rows are rendered here.
    class HasManyRowComponent < ApplicationComponent
      # @param form [ActionView::Helpers::FormBuilder] a nested form builder from fields_for
      # @param form_component [Class] the component rendering the fields for the row
      def initialize(form:, form_component:)
        @form = form
        @form_component = form_component
        super()
      end

      attr_reader :form, :form_component
    end
  end
end
