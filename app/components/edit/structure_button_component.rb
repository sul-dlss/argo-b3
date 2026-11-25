# frozen_string_literal: true

module Edit
  # Component for the button to structure (or clear and structure again) the files of a content.
  class StructureButtonComponent < ApplicationComponent
    # @param [Content] content_record the mutable Content
    def initialize(content_record:)
      @content_record = content_record
      super()
    end

    def structure_button_label
      return t('edit.contents.structure.buttons.structure') if content_record.content_file_sets.none?

      t('edit.contents.structure.buttons.restructure')
    end

    private

    attr_reader :content_record
  end
end
