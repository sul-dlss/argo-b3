# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a strategy for creating a document: each PDF is placed in its own document file set and
    # each other file is placed in its own file file set.
    class Document < Base
      PDF_MIME_TYPE = 'application/pdf'
      DOCUMENT_FILE_SET_TYPE = 'document'
      FILE_FILE_SET_TYPE = 'file'

      # @return [Array<Symbol>] the reasons that the content cannot be structured as a document.
      def self.disqualifying_reasons(content:, **)
        [].tap do |reasons|
          reasons << :no_pdfs if content.content_file_binaries.none? { |binary| pdf?(binary.mime_type) }
        end
      end

      def self.pdf?(mime_type)
        mime_type == PDF_MIME_TYPE
      end

      delegate :pdf?, to: :class

      # For this strategy, structuring and appending are the same: Base clears the structure before
      # structuring, which leaves every binary unassociated.
      def structure
        create_content_file_sets
      end

      def append
        create_content_file_sets
      end

      private

      # The documents come before the other files, with each retaining the path ordering.
      # New file sets are positioned at the end of the existing file sets by the positioning gem.
      def create_content_file_sets
        pdf_content_file_binaries, other_content_file_binaries =
          unassociated_content_file_binaries.path_order.partition { |binary| pdf?(binary.mime_type) }

        pdf_content_file_binaries.each do |content_file_binary|
          create_content_file_set(content_file_binary:, file_set_type: DOCUMENT_FILE_SET_TYPE)
        end
        other_content_file_binaries.each do |content_file_binary|
          create_content_file_set(content_file_binary:, file_set_type: FILE_FILE_SET_TYPE)
        end
      end

      def create_content_file_set(content_file_binary:, file_set_type:)
        content_file_set = content.content_file_sets.create!(file_set_type:, label: label_for(file_set_type))
        content_file_set.content_files.create!(
          content_file_binary:,
          label: content_file_binary.filepath,
          **Contents::FileAttributes.call(mime_type: content_file_binary.mime_type, dark: dark?),
          **file_access_attributes
        )
      end
    end
  end
end
