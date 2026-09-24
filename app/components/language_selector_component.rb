# frozen_string_literal: true

# Show the language selection controls for OCR text extraction workflows
class LanguageSelectorComponent < ApplicationComponent
  # Selecting more than this many languages degrades recognition, so warn the user.
  MAX_RECOMMENDED_LANGUAGES = 8
  ABBYY_LANGUAGES = YAML.load_file(Rails.root.join('config/abbyy_languages.yml')).freeze

  def initialize(form:)
    @form = form
    super()
  end

  # Pairs each language's display label with its ABBYY identifier, which is the label with
  # spaces and parentheses removed (e.g., 'Armenian (Eastern)' becomes 'ArmenianEastern').
  # The identifier is what gets submitted, since ocrWF copies it verbatim into the
  # <Language> elements of the ABBYY ticket XML.
  def available_ocr_languages
    ABBYY_LANGUAGES.map { |language| [language, language.gsub(/[ ()]/, '')] }
  end

  attr_reader :form
end
