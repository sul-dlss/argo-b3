# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for an agreement, in which each Resource
    # (ContentFileSet) is a file Resource with exactly one dark, preserved, unpublished file without a role.
    #
    # Agreements are always dark, so violations are errors rather than warnings. Unlike the other validators,
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
        errors << "#{name} must have exactly one file." unless content_file_set.content_files.one?
        errors << "#{name} is not a file resource." unless content_file_set.file_set_type == FileSetTypes::FILE
        content_file_set.content_files.each do |content_file|
          validate_content_file(content_file:, name:)
        end
      end

      def validate_content_file(content_file:, name:)
        file_name = "#{name} file #{content_file.filepath}"
        errors << "#{file_name} is not dark." unless dark_file?(content_file)
        errors << "#{file_name} must be preserved and not published." unless preserved_unpublished?(content_file)
        errors << "#{file_name} must not have a role." if content_file.use.present?
      end

      def dark_file?(content_file)
        AccessRightsSupport.dark?(view: content_file.view, download: content_file.download,
                                  location: content_file.location)
      end

      def preserved_unpublished?(content_file)
        content_file.preserve && !content_file.publish
      end
    end
  end
end
