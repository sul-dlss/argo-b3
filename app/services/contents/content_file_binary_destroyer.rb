# frozen_string_literal: true

module Contents
  # Deletes binaries, along with the files (in any resource) that reference them.
  # A resource that is left with no files is also deleted; a resource that had no files to begin with is not.
  # Staged copies are kept until the next staging (see StageFilesJob), since the cocina object still references them.
  class ContentFileBinaryDestroyer
    def self.call(...)
      new(...).call
    end

    # @param [Array<ContentFileBinary>] content_file_binaries
    def initialize(content_file_binaries:)
      @content_file_binaries = content_file_binaries
    end

    def call
      ActiveRecord::Base.transaction do
        # Captured before destroying, since destroying the binaries destroys the files.
        content_file_set_ids = ContentFile.where(content_file_binary: content_file_binaries)
                                          .distinct.pluck(:content_file_set_id)
        content_file_binaries.each(&:destroy!)
        ContentFileSet.where(id: content_file_set_ids).where.missing(:content_files).find_each(&:destroy!)
      end
    end

    private

    attr_reader :content_file_binaries
  end
end
