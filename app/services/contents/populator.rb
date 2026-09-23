# frozen_string_literal: true

module Contents
  # Populates an existing Content with ContentFileSets, ContentFiles, and ContentFileBinaries
  # from uploaded files, attaching each uploaded binary.
  # Populator filters out files that should be ignored and determines a specific populator to call
  # based on content type and other considerations.
  class Populator
    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    # @param [Cocina::Models::DROWithMetadata] cocina_object
    # @param [Hash] files uploaded files keyed by their upload index
    # @param [Hash] paths full filepaths keyed by their upload index
    def initialize(content:, cocina_object:, files:, paths:)
      @content = content
      @cocina_object = cocina_object
      @files = files
      @paths = paths
    end

    def call
      # Currently the only populator
      Contents::Populators::FileSetPerFile.call(content:, cocina_object:, files: retained_files,
                                                paths: retained_paths)
    end

    private

    attr_reader :content, :cocina_object, :files, :paths

    # @return [Array<String>] the upload indexes of the files that should not be ignored
    def retained_indexes
      @retained_indexes ||= files.keys.reject { |index| IgnoreFileService.call(filepath: paths[index]) }
    end

    def retained_files
      files.slice(*retained_indexes)
    end

    def retained_paths
      paths.slice(*retained_indexes)
    end
  end
end
