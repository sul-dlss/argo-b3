# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for a 3d object, whose model (GLB) is in a 3d
    # Resource (ContentFileSet) and whose other published files are in file Resources.
    #
    # Violations of the rules for a Resource are errors, except for a dark object, for
    # which they are only warnings since none of its files are expected to be published.
    class ThreeDimensional < Default
      PUBLISHABLE_FILE_SET_TYPES = [FileSetTypes::THREE_DIMENSIONAL, FileSetTypes::FILE].freeze

      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, index:)
        end
        warnings << 'There is not exactly one 3D resource containing exactly one GLB file.' unless one_model_resource?

        result
      end

      private

      def validate_content_file_set(content_file_set:, index:)
        return if PUBLISHABLE_FILE_SET_TYPES.include?(content_file_set.file_set_type)
        return if content_file_set.content_files.none?(&:publish)

        name = resource_name_for(content_file_set:, index:)
        add_warning_or_error("#{name} has published files but is not a 3D or file resource.")
      end

      def one_model_resource?
        three_dimensional_content_file_sets = content_file_sets.select do |content_file_set|
          content_file_set.file_set_type == FileSetTypes::THREE_DIMENSIONAL
        end
        return false unless three_dimensional_content_file_sets.one?

        three_dimensional_content_file_sets.first.content_files.one? do |content_file|
          content_file.mime_type == MimeTypes::GLTF_BINARY
        end
      end
    end
  end
end
