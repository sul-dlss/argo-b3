# frozen_string_literal: true

module Edit
  # Component for selecting the language of a file.
  # The user can select a common language tag or enter another one.
  class LanguageTagComponent < ApplicationComponent
    # Ordered from most to least common in SDR.
    LANGUAGE_TAGS = %w[
      en
      lv
      de
      ru
      es
      ar
      hi
      ur
      pt
      fr
      zh
    ].freeze

    # @param form [ActionView::Helpers::FormBuilder] a nested form builder for a ContentFileForm
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    # Includes the current language tag when it is not a common one, so that it remains selected.
    def options
      language_tag = form.object.language_tag
      return LANGUAGE_TAGS if language_tag.blank? || LANGUAGE_TAGS.include?(language_tag)

      [language_tag, *LANGUAGE_TAGS]
    end
  end
end
