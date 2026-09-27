# frozen_string_literal: true

# Form object for editing a ContentFile (file) within a ContentFileSetForm (resource)
class ContentFileForm < ApplicationForm
  PUBLISH_AND_PRESERVE = 'publish_and_preserve'
  PUBLISH_ONLY = 'publish_only'
  PRESERVE_ONLY = 'preserve_only'
  ADMINISTRATIVE_OPTIONS = [PUBLISH_AND_PRESERVE, PUBLISH_ONLY, PRESERVE_ONLY].freeze

  inherit_attributes_from ContentFile, only: %i[id use view download location]
  # Stored on the ContentFileBinary, so shared by every file that references the binary.
  attribute :mime_type, :string
  # For display only; not editable.
  attribute :filepath, :string
  # Maps to publish and preserve. Nil when the file is neither published nor preserved.
  attribute :administrative, :string

  normalizes_whitespace :use, :mime_type

  # A file that is being deleted does not need to be valid.
  validates :mime_type, presence: true, unless: :marked_for_destruction?
  validate :validate_access, unless: :marked_for_destruction?
  validate :validate_administrative, unless: :marked_for_destruction?

  # The location field is disabled (and so not submitted) when it does not apply, so it is cleared here.
  before_validation :clear_location, unless: :location_applies?

  def self.immutable_attributes
    [:filepath]
  end

  def self.permitted_params
    super + [:_destroy]
  end

  def from_model(content_file)
    super
    self.administrative = administrative_for(publish: content_file.publish, preserve: content_file.preserve)
    self
  end

  def publish?
    [PUBLISH_AND_PRESERVE, PUBLISH_ONLY].include?(administrative)
  end

  def preserve?
    [PUBLISH_AND_PRESERVE, PRESERVE_ONLY].include?(administrative)
  end

  private

  def administrative_for(publish:, preserve:)
    if publish && preserve
      PUBLISH_AND_PRESERVE
    elsif publish
      PUBLISH_ONLY
    elsif preserve
      PRESERVE_ONLY
    end
  end

  # The error is added to administrative_options (rather than administrative) so that it is rendered once
  # for the fieldset instead of for each radio button.
  def validate_administrative
    return if ADMINISTRATIVE_OPTIONS.include?(administrative)

    errors.add(:administrative_options, 'must be selected')
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

    errors.add(:view, 'is not a valid combination of view, download, and location')
  end
end
