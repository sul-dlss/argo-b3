# frozen_string_literal: true

# Form object for updating the details of an Item (DRO) when managing its content.
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ContentsItemForm < CocinaModels::Dro
  include PermittedParamsConcern
  include TextExtractionConcern
  include VersionDescriptionConcern

  # The initial version's description is set at registration, so it is not entered.
  validates :version_description, presence: true, unless: :initial_version?

  # Attributes of the form that are not part of the Cocina object, so changing only them is not a change to save.
  FORM_ONLY_ATTRIBUTES = %w[version_description perform_ocr ocr_languages].freeze

  # The Content being deposited, which is not an attribute so that setting it does not make the form dirty.
  attr_accessor :content

  # The disabled viewing direction select is not submitted, so a previous viewing direction is retained
  # when changing to a content type that does not have viewing directions.
  before_validation :clear_viewing_direction, unless: lambda {
    Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS.include?(content_type)
  }

  # Likewise, the OCR settings are retained when changing to a content type that cannot be OCRed.
  before_validation :clear_perform_ocr, unless: lambda {
    Sdr::TextExtraction::SUPPORTED_TYPES.include?(content_type)
  }
  before_validation :clear_ocr_languages, unless: :perform_ocr

  # Only depositing requires the structure (content) to be valid for the content type.
  # The content errors themselves are shown by the structure validation frame.
  validate :content_valid_for_content_type, on: :deposit

  def self.permitted_params
    [:content_type, :viewing_direction, :perform_ocr, :version_description, { ocr_languages: [] }]
  end

  # Saves the OCR settings with the content. Then opens a new version if the version is closed (since staging
  # always updates the structure); otherwise updates the description of the open version if it changed.
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:)
    validate!
    content&.update!(ocr_settings_attributes)
    prepare_version!(user_name:, open_version: true)
    super
  ensure
    # Keeps the content on the object's current lock, even if saving failed after opening a version.
    content&.update!(lock: previous_cocina_object.lock)
  end

  def changed?
    (changed - FORM_ONLY_ATTRIBUTES).any? || tracked_associations_changed?
  end

  private

  def clear_viewing_direction
    self.viewing_direction = nil
  end

  def clear_perform_ocr
    self.perform_ocr = false
  end

  def clear_ocr_languages
    self.ocr_languages = []
  end

  def content_valid_for_content_type
    return if Contents::Validator.call(content:, cocina_object: previous_cocina_object, content_type:).valid?

    errors.add(:content, I18n.t('edit.contents.fields.content.validations.invalid'))
  end
end
