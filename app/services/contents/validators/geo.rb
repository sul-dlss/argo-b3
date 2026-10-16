# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for geo, which must have exactly one object Resource.
    #
    # Violations are errors, except for a dark object, for which they are only warnings
    # since none of its files are expected to be published.
    class Geo < Default
      # @return [Contents::Validators::Result]
      def call
        object_resource_count = content_file_sets.count do |content_file_set|
          content_file_set.file_set_type == FileSetTypes::OBJECT
        end
        add_warning_or_error('There are no object resources.') if object_resource_count.zero?
        add_warning_or_error('There is more than one object resource.') if object_resource_count > 1

        result
      end
    end
  end
end
