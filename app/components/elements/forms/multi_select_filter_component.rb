# frozen_string_literal: true

module Elements
  module Forms
    # Multiple select with checkbox options (Tom Select), for filtering.
    class MultiSelectFilterComponent < SdrViewComponents::Forms::SelectFieldComponent
      # @param select_all [Boolean] whether the dropdown has Select all / Select none buttons
      def initialize(select_all: true, **)
        @select_all = select_all
        super(**)
      end

      def input_args
        args = super
        data = { controller: 'checkbox-tom-select', checkbox_tom_select_select_all_value: @select_all }
        args.merge(multiple: true, data: data.merge(args.fetch(:data, {})))
      end
    end
  end
end
