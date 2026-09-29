# frozen_string_literal: true

# Form object for editing a ContentFileSet (resource) and its ContentFiles (files)
class ContentFileSetForm < ApplicationForm
  inherit_attributes_from ContentFileSet, only: %i[id label file_set_type]
  has_many :content_files, allow_destroy: true

  def self.immutable_attributes
    [:id]
  end

  attr_reader :content_file_set

  def from_model(content_file_set)
    @content_file_set = content_file_set
    super
  end

  # Saves the resource and its files. Deleting a file also deletes its binary (including any staged copy)
  # when no other file references it. Deleting every file deletes the resource.
  # Note that this deliberately does not check changed?, since a save may only change the nested files.
  # @return [Boolean] true if saved, false if invalid
  def save # rubocop:disable Naming/PredicateMethod
    return false unless valid?

    destroyed_content_file_binaries = ActiveRecord::Base.transaction do
      # Captured before saving, since saving destroys the files.
      content_file_binary_ids = removed_content_file_binary_ids
      content_file_set.update!(label:, file_set_type:, content_files_attributes:)
      update_content_file_binaries
      destroy_content_file_set_if_all_files_removed
      destroy_unreferenced_content_file_binaries(content_file_binary_ids:)
    end
    after_commit_destroying(content_file_binaries: destroyed_content_file_binaries)
    true
  end

  # Deletes the resource and its files, as well as their binaries (including any staged copies)
  # when no other file references them. Unlike save, this also deletes a resource that has no files.
  def destroy
    destroyed_content_file_binaries = ActiveRecord::Base.transaction do
      # Captured before destroying, since destroying the resource destroys the files.
      content_file_binary_ids = content_file_set.content_files.pluck(:content_file_binary_id)
      content_file_set.destroy!
      destroy_unreferenced_content_file_binaries(content_file_binary_ids:)
    end
    after_commit_destroying(content_file_binaries: destroyed_content_file_binaries)
  end

  # @return [Boolean] true if the save deleted the resource
  delegate :destroyed?, to: :content_file_set, prefix: true

  # @return [Boolean] true if the save deleted any binaries (only set after a successful save)
  def content_file_binaries_destroyed?
    @content_file_binaries_destroyed
  end

  private

  # Using ActiveRecord nested attributes (rather than looking up each ContentFile by id)
  # ensures that only files belonging to this resource can be updated or deleted.
  def content_files_attributes
    content_files.map do |content_file_form|
      {
        id: content_file_form.id,
        use: content_file_form.use,
        _destroy: content_file_form.marked_for_destruction?
      }
    end
  end

  # Mime type is stored on the binary (and so shared by every file that references it).
  # Looking up the binaries through the file set's files ensures that only this resource's binaries are updated.
  def update_content_file_binaries
    content_file_forms_by_id = content_files.reject(&:marked_for_destruction?).index_by(&:id)
    content_file_set.content_files.where(id: content_file_forms_by_id.keys).includes(:content_file_binary)
                    .find_each do |content_file|
      content_file.content_file_binary.update!(mime_type: content_file_forms_by_id.fetch(content_file.id).mime_type)
    end
  end

  # A resource that had no files to begin with is not deleted.
  def destroy_content_file_set_if_all_files_removed
    return unless content_files.any?(&:marked_for_destruction?)

    content_file_set.destroy! if content_file_set.content_files.reload.none?
  end

  # The binaries of the files marked for deletion. These are candidates for deletion; a binary is only deleted
  # if no other file references it (see destroy_unreferenced_content_file_binaries).
  # This must be called before saving, since saving destroys the files that reference the binaries.
  # Scoping to the file set's files means that files from other resources are ignored.
  # @return [Array<Integer>] ids of the binaries of the files marked for deletion
  def removed_content_file_binary_ids
    content_file_ids = content_files.select(&:marked_for_destruction?).map(&:id)
    content_file_set.content_files.where(id: content_file_ids).pluck(:content_file_binary_id)
  end

  # @return [Array<ContentFileBinary>] the destroyed binaries (those no longer referenced by any file)
  def destroy_unreferenced_content_file_binaries(content_file_binary_ids:)
    content_file_binaries = ContentFileBinary.unassociated
                                             .where(id: content_file_binary_ids)
                                             .includes(:content)
                                             .to_a
    content_file_binaries.each(&:destroy!)
  end

  # Staged files are deleted after commit, since deleting a file cannot be rolled back.
  def after_commit_destroying(content_file_binaries:)
    @content_file_binaries_destroyed = content_file_binaries.any?
    FileUtils.rm_f(staging_filepaths_for(content_file_binaries))
  end

  # @return [Array<String>] the staging filepaths of the binaries that had been staged
  def staging_filepaths_for(content_file_binaries)
    content_file_binaries.select(&:file_location_stage?).map do |content_file_binary|
      StagingSupport.staging_filepath(druid: content_file_binary.content.druid, filepath: content_file_binary.filepath)
    end
  end
end
