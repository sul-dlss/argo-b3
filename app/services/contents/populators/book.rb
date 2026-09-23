# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a strategy for creating a book: the files that share a filename (ignoring the extension),
    # e.g., the master, the deliverable, and the OCR for a page, are grouped into a single file set.
    # Ported from pre-assembly's simple book content metadata creation style.
    class Book < Base
      IMAGE_MIME_TYPE_PREFIX = 'image/'
      # The mime types of the files that, when accompanying an image, indicate that a file set contains OCR.
      OCR_MIME_TYPES = ['application/xml', 'application/pdf', 'text/plain'].freeze
      PAGE_FILE_SET_TYPE = 'page'
      OBJECT_FILE_SET_TYPE = 'object'
      DARK_VIEW = 'dark'

      # Grouping the files of a book by filename only works when the files are not organized into folders,
      # and there are no pages to group the files into when there are no images. Structuring a dark object
      # as a book is pointless, since none of its files are shelved or published.
      # @return [Array<Symbol>] the reasons that the content cannot be structured as a book.
      def self.disqualifying_reasons(content:, cocina_object:)
        content_file_binaries = content.content_file_binaries
        [].tap do |reasons|
          reasons << :dark if cocina_object.access.view == DARK_VIEW
          reasons << :hierarchical_files if content_file_binaries.any?(&:hierarchical?)
          reasons << :no_images if content_file_binaries.none? { |binary| image?(binary.mime_type) }
        end
      end

      def self.image?(mime_type)
        mime_type&.start_with?(IMAGE_MIME_TYPE_PREFIX) || false
      end

      delegate :image?, to: :class

      # Base has already cleared the structure, so every binary is unassociated.
      def structure
        ordered_grouped_content_file_binaries.each_value do |content_file_binaries|
          create_content_file_set(content_file_binaries:)
        end
      end

      # New binaries join the file set for an existing file with the same basename, e.g., OCR that is
      # uploaded after the book has already been structured. The existing file set's type, label, and position
      # are left alone; re-structuring is the way to get a clean re-derivation.
      def append
        ordered_grouped_content_file_binaries.each do |basename, content_file_binaries|
          content_file_set = existing_content_file_sets_by_basename[basename]
          next create_content_file_set(content_file_binaries:) if content_file_set.nil?

          append_to_content_file_set(content_file_set:, content_file_binaries:)
        end
      end

      private

      # The pages of a book come before the file sets that are not pages, e.g., a PDF of the whole book.
      # The index breaks ties so that the filepath ordering within each file set type is retained.
      # @return [Hash<String,Array<ContentFileBinary>>] the binaries by basename, in the order to be created.
      def ordered_grouped_content_file_binaries
        grouped_content_file_binaries.sort_by.with_index do |(_basename, content_file_binaries), index|
          [file_set_type_for(content_file_binaries) == PAGE_FILE_SET_TYPE ? 0 : 1, index]
        end.to_h
      end

      # Ordering by filepath so that, e.g., page_0001 precedes page_0002 regardless of the order of upload.
      # @return [Hash<String,Array<ContentFileBinary>>] the unassociated binaries grouped by basename,
      #   in order of first appearance.
      def grouped_content_file_binaries
        unassociated_content_file_binaries.order(:filepath).group_by(&:basename)
      end

      # @return [Hash<String,ContentFileSet>] the already structured file sets by basename. When more than one
      #   file set matches a basename (possible when the structure has been edited by hand), the file set
      #   with the lowest position wins.
      def existing_content_file_sets_by_basename
        @existing_content_file_sets_by_basename ||=
          content.content_file_sets.includes(content_files: :content_file_binary)
                 .each_with_object({}) do |content_file_set, lookup|
            content_file_set.content_files.each do |content_file|
              lookup[content_file.content_file_binary.basename] ||= content_file_set
            end
          end
      end

      # Adding OCR to a file set changes the attributes of the files that are already in it, e.g., the
      # deliverable image becomes preserved. The existing files are only updated when the OCR status changes,
      # so that appending to a file set does not otherwise overwrite attributes that have been edited by hand.
      def append_to_content_file_set(content_file_set:, content_file_binaries:)
        existing_content_files = content_file_set.content_files.to_a
        was_ocr = ocr?(existing_content_files.map(&:content_file_binary))
        ocr = ocr?(existing_content_files.map(&:content_file_binary) + content_file_binaries)

        create_content_files(content_file_set:, content_file_binaries:, ocr:)
        return unless ocr && !was_ocr

        existing_content_files.each do |content_file|
          content_file.update!(**Contents::FileAttributes.call(mime_type: content_file.mime_type, ocr:))
        end
      end

      # New file sets are positioned at the end of the existing file sets by the positioning gem.
      def create_content_file_set(content_file_binaries:)
        file_set_type = file_set_type_for(content_file_binaries)
        content_file_set = content.content_file_sets.create!(file_set_type:, label: label_for(file_set_type))
        create_content_files(content_file_set:, content_file_binaries:, ocr: ocr?(content_file_binaries))
      end

      def create_content_files(content_file_set:, content_file_binaries:, ocr:)
        content_file_binaries.each do |content_file_binary|
          content_file_set.content_files.create!(
            content_file_binary:,
            label: content_file_binary.filepath,
            **Contents::FileAttributes.call(mime_type: content_file_binary.mime_type, ocr:),
            **file_access_attributes
          )
        end
      end

      # All of the file sets in a book are pages, unless a file set contains no images at all.
      def file_set_type_for(content_file_binaries)
        return PAGE_FILE_SET_TYPE if content_file_binaries.any? { |binary| image?(binary.mime_type) }

        OBJECT_FILE_SET_TYPE
      end

      # Whereas pre-assembly asks the user whether a batch has OCR, here it is inferred from the files
      # that are grouped into a file set.
      def ocr?(content_file_binaries)
        mime_types = content_file_binaries.map(&:mime_type)
        mime_types.any? { |mime_type| image?(mime_type) } && mime_types.intersect?(OCR_MIME_TYPES)
      end

      # Labels are numbered per file set type, e.g., Page 1, Page 2, Object 1. When appending,
      # numbering continues from the file sets that already exist.
      def label_for(file_set_type)
        file_set_type_counts[file_set_type] += 1
        "#{file_set_type.capitalize} #{file_set_type_counts[file_set_type]}"
      end

      def file_set_type_counts
        @file_set_type_counts ||= content.content_file_sets.reorder(nil).group(:file_set_type).count
                                         .tap do |counts|
          counts.default = 0
        end
      end
    end
  end
end
