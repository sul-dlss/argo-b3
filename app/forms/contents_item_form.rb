# frozen_string_literal: true

# Form object for updating the details of an Item (DRO) when managing its content.
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ContentsItemForm < CocinaModels::Dro
  include PermittedParamsConcern
  include TextExtractionConcern
  include VersionDescriptionConcern
  include EmbargoFormConcern
  include FileAccessFormConcern

  # The initial version's description is set at registration, so it is not entered.
  validates :version_description, presence: true, unless: :initial_version?

  # Attributes of the form that are not part of the Cocina object, so changing only them is not a change to save.
  FORM_ONLY_ATTRIBUTES = %w[version_description perform_ocr ocr_languages perform_speech_to_text with_embargo
                            overwrite_file_access].freeze

  # The Content being deposited, which is not an attribute so that setting it does not make the form dirty.
  attr_accessor :content

  # The disabled viewing direction select is not submitted, so a previous viewing direction is retained
  # when changing to a content type that does not have viewing directions.
  before_validation :clear_viewing_direction, unless: lambda {
    Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS.include?(content_type)
  }

  # Likewise, the text extraction settings are retained when changing to a content type that does not have
  # that text extraction.
  before_validation :clear_perform_ocr, unless: -> { Sdr::TextExtraction.ocr_type?(content_type) }
  before_validation :clear_ocr_languages, unless: :perform_ocr
  before_validation :clear_perform_speech_to_text, unless: -> { Sdr::TextExtraction.speech_to_text_type?(content_type) }

  # Only depositing requires the structure (content) to be valid for the content type.
  # The content errors themselves are shown by the structure validation frame.
  validate :content_valid_for_content_type, on: :deposit

  # The access fields, which structuring also uses (before they are saved) to set the access of files.
  ACCESS_PARAMS = %i[with_embargo embargo_release_date access_view access_download access_location
                     embargo_view embargo_download embargo_location].freeze

  def self.permitted_params
    [:content_type, :viewing_direction, :perform_ocr, :perform_speech_to_text, :version_description,
     :overwrite_file_access, { ocr_languages: [] }, *ACCESS_PARAMS]
  end

  # Saves the text extraction settings with the content. Then opens a new version if the version is closed (since
  # staging always updates the structure); otherwise updates the description of the open version if it changed.
  # Afterwards, applies a change to the access to the content's files, so that staging them saves it.
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:)
    validate!
    content&.update!(text_extraction_settings_attributes)
    prepare_version!(user_name:, open_version: true)
    overwrite = content_file_access_overwrite
    super
    overwrite_content_file_access!(overwrite)
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

  def clear_perform_speech_to_text
    self.perform_speech_to_text = false
  end

  # Validated against the object as edited, since the form may change its access.
  # Skipped when the edited object cannot be built, since the invalid fields have their own errors.
  def content_valid_for_content_type
    return if Contents::Validator.call(content:, cocina_object: mutated_cocina_object, content_type:,
                                       saved_access: previous_cocina_object.access).valid?

    errors.add(:content, I18n.t('edit.contents.fields.content.validations.invalid'))
  rescue Cocina::Models::ValidationError
    nil
  end
end
