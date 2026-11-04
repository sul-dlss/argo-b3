# frozen_string_literal: true

# Applies a change to an Item's access to its files, in the cocina object and the mutable Content; overrides
# mutated_cocina_object. Requires content (or nil), previous_cocina_object and the access_* attributes.
module FileAccessFormConcern
  extend ActiveSupport::Concern

  included do
    attribute :overwrite_file_access, :boolean, default: true
  end

  private

  # Built before saving, since saving replaces the previous cocina object's access with the edited access.
  # @return [Contents::FileAccessOverwrite]
  def content_file_access_overwrite
    Contents::FileAccessOverwrite.new(
      previous_access: previous_cocina_object.access,
      access: { view: access_view, download: access_download, location: access_location },
      overwrite: overwrite_file_access
    )
  end

  # @param overwrite [Contents::FileAccessOverwrite]
  def overwrite_content_file_access!(overwrite)
    return unless content && overwrite.apply?

    content.content_files.update_all(overwrite.content_file_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  def mutated_cocina_object
    CocinaObjectMutators::DroMutator.call(cocina_object: previous_cocina_object, cocina_model: self,
                                          file_access_overwrite: content_file_access_overwrite)
  end
end
