# frozen_string_literal: true

# Form object for updating the details of an Item (DRO) when managing its content.
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ContentsItemForm < CocinaModels::Dro
  include PermittedParamsConcern
  include TextExtractionConcern
  include EditCocinaObjectFormConcern
  include EmbargoFormConcern
  include FileAccessFormConcern

  form_only_attributes :perform_ocr, :ocr_languages, :perform_speech_to_text, :with_embargo, :overwrite_file_access

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

  # @param cocina_object [Cocina::Models::DROWithMetadata]
  # @param version_service [Sdr::VersionService]
  # @param content [Content] the mutable Content, whose saved item details are applied to the form
  # @param params [ActionController::Parameters, Hash] the submitted params, applied after the saved item details
  # @return [ContentsItemForm] the form for managing files
  def self.for_manage_files(cocina_object, version_service:, content:, params: {})
    for_edit(cocina_object, version_service:).tap do |form|
      form.content = content
      form.prefill_text_extraction_settings(content)
      form.update(content.item_details_params)
      form.update(params)
    end
  end

  # @return [Boolean] true if the fields of the item details step are valid
  def item_details_valid?
    valid?
    # The version description is entered on the deposit step.
    errors.delete(:version_description)
    errors.empty?
  end

  # Saves the item details with the content, without saving them to the object, e.g., when moving to another step.
  # @param attributes [Hash] other attributes of the content to update, e.g., the step
  def save_item_details!(**attributes)
    content.update!(**self.attributes.slice(*Content::ITEM_DETAILS_ATTRIBUTES), **text_extraction_settings_attributes,
                    **attributes)
  end

  private

  # Staging always updates the structure, so a closed version is always opened.
  def open_version_on_save? = true

  # The initial version's description is set at registration, so it is not entered.
  def version_description_required? = !initial_version?

  # Saves the text extraction settings with the content, and applies a change to the access to the content's files
  # so that staging them saves it. The item details are then saved to the object, so the flow starts over.
  def around_content_save(**)
    content&.update!(text_extraction_settings_attributes)
    overwrite = content_file_access_overwrite
    yield
    overwrite_content_file_access!(overwrite)
    content&.reset_manage_files_flow!
  ensure
    # Keeps the content on the object's current lock, even if saving failed after opening a version.
    content&.update!(lock: previous_cocina_object.lock)
  end

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
