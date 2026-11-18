# frozen_string_literal: true

# Form for extracting text (OCR or speech to text, by content type) from an Item, now or at its next deposit.
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ItemTextExtractionForm < CocinaModels::Dro
  model_name_for :text_extraction

  include PermittedParamsConcern
  include TextExtractionConcern
  include ContentDepositFormConcern

  form_only_attributes :perform_ocr, :ocr_languages, :perform_speech_to_text

  # Only the version description and languages are submitted, so nothing else about the item can be changed.
  def self.permitted_params
    [:version_description, { ocr_languages: [] }]
  end

  # A Draft keeps its description; otherwise the new version is described as text extraction.
  def prefill_version_description
    super
    return if version_description.present?

    self.version_description = I18n.t('edit.item_text_extractions.new.default_version_description')
  end

  # A background job may change the lock or structure of a busy Content, so saving is refused.
  def content_busy?
    content&.busy?
  end

  private

  # The text extraction for the item's content type always runs; it is not submitted.
  def assign_from_cocina_object(cocina_object)
    super
    self.perform_ocr = Sdr::TextExtraction.ocr_type?(content_type)
    self.perform_speech_to_text = Sdr::TextExtraction.speech_to_text_type?(content_type)
  end

  def open_version_on_save? = true

  # Saving as a draft saves the settings to the mutable Content (creating it if needed), which follows the object to
  # its new lock. Depositing doesn't need the Content, which matches what is deposited, so it is deleted.
  def around_content_save(accession:)
    unless accession
      self.content ||= Contents::Builder.find_or_create(cocina_object: previous_cocina_object, immutable: false)
    end
    content&.update!(text_extraction_settings_attributes)
    yield
    content&.destroy! if accession
  ensure
    rebase_content_lock
  end

  def workflow_context
    Content.workflow_context(content_type:, **text_extraction_settings_attributes)
  end
end
