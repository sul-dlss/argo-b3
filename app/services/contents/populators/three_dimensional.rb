# frozen_string_literal: true

module Contents
  module Populators
    # Populates an existing Content with ContentFileSets and ContentFiles for the ContentFileBinaries
    # that are not yet part of its structure.
    # It uses a strategy for creating a 3d object: the first model file is placed in a 3d file set and
    # each other file is placed in its own file file set.
    class ThreeDimensional < Base
      MODEL_MIME_TYPE = 'model/gltf-binary'
      THREE_DIMENSIONAL_FILE_SET_TYPE = '3d'
      FILE_FILE_SET_TYPE = 'file'

      # @return [Array<Symbol>] the reasons that the content cannot be structured as a 3d object.
      def self.disqualifying_reasons(content:, **)
        [].tap do |reasons|
          reasons << :no_models if content.content_file_binaries.none? { |binary| model?(binary.mime_type) }
        end
      end

      def self.model?(mime_type)
        mime_type == MODEL_MIME_TYPE
      end

      delegate :model?, to: :class

      # Base has already cleared the structure, so every binary is unassociated.
      # The 3d file set comes before the other files, which retain the path ordering.
      def structure
        content_file_binaries = unassociated_content_file_binaries.path_order.to_a
        model_content_file_binary = content_file_binaries.find { |binary| model?(binary.mime_type) }

        if model_content_file_binary
          create_content_file_set(content_file_binary: model_content_file_binary,
                                  file_set_type: THREE_DIMENSIONAL_FILE_SET_TYPE, label: '')
        end
        create_file_content_file_sets(content_file_binaries: content_file_binaries - [model_content_file_binary])
      end

      # Appended binaries, including any additional model files, are each placed in their own file file set.
      # Re-structuring is the way to get a clean re-derivation.
      def append
        create_file_content_file_sets(content_file_binaries: unassociated_content_file_binaries.path_order)
      end

      private

      # New file sets are positioned at the end of the existing file sets by the positioning gem.
      def create_file_content_file_sets(content_file_binaries:)
        content_file_binaries.each do |content_file_binary|
          create_content_file_set(content_file_binary:, file_set_type: FILE_FILE_SET_TYPE,
                                  label: label_for(FILE_FILE_SET_TYPE))
        end
      end

      def create_content_file_set(content_file_binary:, file_set_type:, label:)
        content_file_set = content.content_file_sets.create!(file_set_type:, label:)
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
