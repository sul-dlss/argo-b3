# frozen_string_literal: true

module Contents
  module Populators
    # Base class for populators, which populate an existing Content with ContentFileSets and ContentFiles
    # for the ContentFileBinaries that are not yet part of its structure.
    #
    # Subclasses implement a particular strategy by overriding #structure and #append. A subclass that can
    # only handle some contents also overrides .disqualifying_reasons, which PopulatorSelector uses both to
    # select a populator and to explain the selection.
    class Base
      # Clears the existing structure and then builds it from all of the binaries.
      def self.structure(content:, cocina_object:)
        content.content_file_sets.destroy_all

        new(content:, cocina_object:).structure
      end

      # Adds to the existing structure for the binaries that are not yet part of it.
      def self.append(...)
        new(...).append
      end

      # @return [Array<Symbol>] the reasons that this populator cannot be used for the content.
      def self.disqualifying_reasons(**)
        []
      end

      # @param [Content] content
      # @param [Cocina::Models::DROWithMetadata] cocina_object
      def initialize(content:, cocina_object:)
        @content = content
        @cocina_object = cocina_object
      end

      # Builds the structure from the binaries, which are all unassociated since .structure cleared it.
      def structure
        raise NotImplementedError
      end

      def append
        raise NotImplementedError
      end

      private

      attr_reader :content, :cocina_object

      def unassociated_content_file_binaries
        content.content_file_binaries.unassociated
      end

      def default_file_access
        @default_file_access ||= Contents::DefaultFileAccess.new(cocina_object:)
      end

      def file_access_attributes
        default_file_access.attributes
      end

      def dark?
        default_file_access.dark?
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
