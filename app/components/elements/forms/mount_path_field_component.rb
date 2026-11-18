# frozen_string_literal: true

module Elements
  module Forms
    # Text field for a path on a mount, suggesting the mount locations as the user types.
    # The suggestions are the mount roots only; the user continues typing the rest of the path.
    # Accepts the same arguments as SdrViewComponents::Forms::TextFieldComponent.
    class MountPathFieldComponent < ApplicationComponent
      def initialize(form:, field_name:, **args)
        @form = form
        @field_name = field_name
        @args = args
        super()
      end

      attr_reader :form, :field_name, :args

      def text_field_component
        SdrViewComponents::Forms::TextFieldComponent.new(form:, field_name:, input_list: datalist_id,
                                                         input_autocomplete: 'off', **args)
      end

      def datalist_id
        "#{form.field_id(field_name)}_mount_locations"
      end

      # With a trailing slash, so that the user can continue typing a folder on the mount.
      def suggestions
        Settings.mount_locations.map { |location| File.join(location, '') }
      end
    end
  end
end
