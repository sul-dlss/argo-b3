# frozen_string_literal: true

module Contents
  # Discards a mutable Content's unsaved changes by rebuilding its structure from the Cocina object and clearing the
  # item details chosen while managing files. The Content itself (and so its text extraction settings) is kept.
  class UnsavedChangesDiscarder
    # Raised when the Content is staging or discovering.
    class ContentBusyError < StandardError; end
    # Raised when staging failed, since the Content is then the only record of the files that failed to stage.
    class StagingFailedError < StandardError; end

    def self.call(...)
      new(...).call
    end

    # @param content [Content] the mutable Content for the Cocina object's lock
    # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object
    def initialize(content:, cocina_object:)
      @content = content
      @cocina_object = cocina_object
    end

    # @return [Boolean] true if discarded, or false if the page was stale (e.g., the object was changed elsewhere)
    # @raise [ContentBusyError] if the Content is staging or discovering
    # @raise [StagingFailedError] if staging the Content failed
    def call
      return false if stale?

      check_staging_state!

      ActiveRecord::Base.transaction do
        delete_structure
        Contents::Builder.new(cocina_object:, immutable: false).populate(content)
        mark_staged_binaries
        content.reset_manage_files_flow!
      end
      true
    end

    private

    attr_reader :content, :cocina_object

    delegate :druid, to: :content

    def stale?
      content.immutable || content.lock != cocina_object.lock
    end

    def check_staging_state!
      raise ContentBusyError, Content::BUSY_MESSAGE if content.busy?
      raise StagingFailedError, 'Staging failed' if content.staging_failed?
    end

    # Deleted rather than destroyed for speed, except binaries with uploads, so that their uploads are purged.
    def delete_structure
      ContentFile.where(content_file_set: content.content_file_sets).delete_all
      ContentFileSet.where(content:).delete_all
      binaries.joins(:file_attachment).find_each(&:destroy!)
      binaries.delete_all
    end

    # The Builder assumes every file has been deposited, but files staged in the open version have not.
    def mark_staged_binaries
      staged_filepaths = StagingSupport.staged_filepaths(druid:, filepaths: binaries.pluck(:filepath))
      return if staged_filepaths.empty?

      binaries.where(filepath: staged_filepaths.to_a).update_all(file_location: 'stage') # rubocop:disable Rails/SkipsModelValidations
    end

    # Not content.content_file_binaries, whose delete_all would destroy each binary (dependent: :destroy).
    def binaries
      ContentFileBinary.where(content:)
    end
  end
end
