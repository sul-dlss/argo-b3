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

      # The access attributes for a ContentFile, derived from the object's (possibly embargoed) access.
      def file_access_attributes
        access = cocina_object.access.embargo.presence || cocina_object.access
        {
          view: access.view == 'citation-only' ? 'dark' : access.view,
          download: access.download,
          location: access.location
        }
      end
    end
  end
end
