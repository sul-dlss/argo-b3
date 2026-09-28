# frozen_string_literal: true

module Contents
  # Deletes binaries, along with the files (in any resource) that reference them and any staged copies.
  # A resource that is left with no files is also deleted; a resource that had no files to begin with is not.
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
      # Staged files are deleted after all transactions commit (including any that the caller opened),
      # since deleting a file cannot be rolled back.
      filepaths = staging_filepaths
      ActiveRecord.after_all_transactions_commit { FileUtils.rm_f(filepaths) }
    end

    private

    attr_reader :content_file_binaries

    # @return [Array<String>] the staging filepaths of the binaries that had been staged
    def staging_filepaths
      content_file_binaries.select(&:file_location_stage?).map do |content_file_binary|
        StagingSupport.staging_filepath(druid: content_file_binary.content.druid,
                                        filepath: content_file_binary.filepath)
      end
    end
  end
end
