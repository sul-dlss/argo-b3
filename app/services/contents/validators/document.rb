# frozen_string_literal: true

module Contents
  module Validators
    # Validates that the structure of a Content is suitable for a document, whose PDF is in a document Resource
    # (ContentFileSet). A document Resource may publish any files alongside exactly one published PDF
    # (see ResourceRules); other published files are each in their own file Resource.
    #
    # Violations of the rules for a Resource are errors, except for a dark object, for
    # which they are only warnings since none of its files are expected to be published.
    class Document < Default
      include ResourceRules

      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          validate_content_file_set(content_file_set:, index:)
        end
        warnings << 'No document resource has exactly one PDF file.' unless any_document_resource_with_one_pdf?

        result
      end

      private

      def validate_content_file_set(content_file_set:, index:)
        name = resource_name_for(content_file_set:, index:)
        published_content_files = content_file_set.content_files.select(&:publish)

        case content_file_set.file_set_type
        when FileSetTypes::DOCUMENT
          # A document Resource has one published PDF.
          validate_document_resource(content_file_set:, name:)
        when FileSetTypes::FILE
          add_warning_or_error("#{name} has more than one published file.") if published_content_files.many?
        else
          return if published_content_files.none?

          add_warning_or_error("#{name} has published files but is not a document or file resource.")
        end
      end

      def any_document_resource_with_one_pdf?
        content_file_sets.any? do |content_file_set|
          content_file_set.file_set_type == FileSetTypes::DOCUMENT &&
            content_file_set.content_files.one? { |content_file| content_file.mime_type == MimeTypes::PDF }
        end
      end
    end
  end
end
