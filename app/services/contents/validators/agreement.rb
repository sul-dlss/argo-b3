# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for an agreement, in which each Resource
    # (ContentFileSet) is a file Resource with one or more preserved files without a role
    # (e.g., PDF and DOCX versions of the same agreement).
    # Agreements are always dark, so DarkFiles checks that the files are dark and unpublished.
    #
    # Violations are errors rather than warnings. Unlike the other validators,
    # this does not use Default#add_warning_or_error (or the dark: argument), which would make every violation
    # a warning and so never block depositing.
    class Agreement < Default
      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, name: resource_name_for(content_file_set:, index:))
        end

        result
      end

      private

      def validate_content_file_set(content_file_set:, name:)
        errors << "#{name} has no files." if content_file_set.content_files.empty?
        errors << "#{name} is not a file resource." unless content_file_set.file_set_type == FileSetTypes::FILE
        content_file_set.content_files.each do |content_file|
          validate_content_file(content_file:, name:)
        end
      end

      def validate_content_file(content_file:, name:)
        file_name = "#{name} file #{content_file.filepath}"
        errors << "#{file_name} must be preserved." unless content_file.preserve
        errors << "#{file_name} must not have a role." if content_file.use.present?
      end
    end
  end
end
