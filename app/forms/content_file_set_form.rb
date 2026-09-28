# frozen_string_literal: true

# Form object for editing a ContentFileSet (resource) and its ContentFiles (files)
class ContentFileSetForm < ApplicationForm
  inherit_attributes_from ContentFileSet, only: %i[id label file_set_type]
  has_many :content_files

  def self.immutable_attributes
    [:id]
  end

  attr_reader :content_file_set

  def from_model(content_file_set)
    @content_file_set = content_file_set
    super
  end

  # Saves the resource and its files.
  # Note that this deliberately does not check changed?, since a save may only change the nested files.
  # @return [Boolean] true if saved, false if invalid
  def save # rubocop:disable Naming/PredicateMethod
    return false unless valid?

    ActiveRecord::Base.transaction do
      content_file_set.update!(label:, file_set_type:, content_files_attributes:)
      update_content_file_binaries
    end
    true
  end

  private

  # Using ActiveRecord nested attributes (rather than looking up each ContentFile by id)
  # ensures that only files belonging to this resource can be updated.
  def content_files_attributes
    content_files.map do |content_file_form|
      {
        id: content_file_form.id,
        use: content_file_form.use
      }
    end
  end

  # Mime type is stored on the binary (and so shared by every file that references it).
  # Looking up the binaries through the file set's files ensures that only this resource's binaries are updated.
  def update_content_file_binaries
    content_file_forms_by_id = content_files.index_by(&:id)
    content_file_set.content_files.where(id: content_file_forms_by_id.keys).includes(:content_file_binary)
                    .find_each do |content_file|
      content_file.content_file_binary.update!(mime_type: content_file_forms_by_id.fetch(content_file.id).mime_type)
    end
  end
end
