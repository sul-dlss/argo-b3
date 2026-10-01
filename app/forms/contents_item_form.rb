# frozen_string_literal: true

# Form object for updating the details of an Item (DRO) when managing its content.
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ContentsItemForm < CocinaModels::Dro
  include PermittedParamsConcern
  include TextExtractionConcern

  # The OCR settings are not part of the Cocina object; they are form-only attributes that
  # #workflow_context hands to the assembly workflow instead. A consequence is that changing only
  # these still issues a Cocina update that is a no-op.
  attribute :run_ocr, :boolean, default: false

  # The disabled viewing direction select is not submitted, so a previous viewing direction is retained
  # when changing to a content type that does not have viewing directions.
  before_validation :clear_viewing_direction, unless: lambda {
    Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS.include?(content_type)
  }

  # Likewise, the OCR settings are retained when changing to a content type that cannot be OCRed.
  before_validation :clear_run_ocr, unless: lambda {
    Sdr::TextExtraction::SUPPORTED_TYPES.include?(content_type)
  }
  before_validation :clear_text_extraction_languages, unless: :run_ocr

  validates :text_extraction_languages, presence: true, if: :run_ocr

  def self.permitted_params
    [:content_type, :viewing_direction, :run_ocr, { text_extraction_languages: [] }]
  end

  # The assembly workflow reads these from its context to decide whether to run OCR.
  # @return [Hash] the workflow context to start accessioning with
  def workflow_context
    return {} unless run_ocr

    { runOcr: true, ocrLanguages: text_extraction_languages }
  end

  private

  def clear_viewing_direction
    self.viewing_direction = nil
  end

  def clear_run_ocr
    self.run_ocr = false
  end

  def clear_text_extraction_languages
    self.text_extraction_languages = []
  end
end
