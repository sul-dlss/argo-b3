# frozen_string_literal: true

# Form object for editing a ContentFile (file) within a ContentFileSetForm (resource)
class ContentFileForm < ApplicationForm
  # NOTE: A file that is being deleted does not need to be valid so some validation
  # are limited to marked_for_destruction?

  inherit_attributes_from ContentFile, only: %i[id use view download location language_tag corrected_for_accessibility
                                                publish preserve]
  # Stored on the ContentFileBinary, so shared by every file that references the binary.
  attribute :mime_type, :string
  # For display only; not editable.
  attribute :filepath, :string
  # A file must be published, preserved, or both.
  validate :validate_publish_or_preserve, unless: :marked_for_destruction?

  normalizes_whitespace :use, :mime_type, :language_tag

  validates :mime_type, presence: true, unless: :marked_for_destruction?
  validate :validate_access, unless: :marked_for_destruction?

  # The location field is disabled (and so not submitted) when it does not apply, so it is cleared here.
  before_validation :clear_location, unless: :location_applies?

  def self.immutable_attributes
    [:filepath]
  end

  def self.permitted_params
    super + [:_destroy]
  end

  private

  # The error is added to publish, so that it is shown in the file's row.
  def validate_publish_or_preserve
    return if publish || preserve

    errors.add(:publish, I18n.t('edit.content_file_sets.fields.content_files.publish.validations.required'))
  end

  def location_applies?
    [view, download].include?('location-based')
  end

  def clear_location
    self.location = nil
  end

  # Files do not support citation-only access.
  def validate_access
    return if AccessRightsSupport.valid?(view:, download:, location:, citation_only: false)

    errors.add(:view, I18n.t('edit.content_file_sets.fields.content_files.access.validations.invalid'))
  end
end
