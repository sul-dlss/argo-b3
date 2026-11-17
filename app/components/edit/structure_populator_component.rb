# frozen_string_literal: true

module Edit
  # Component for the populator that will be used to structure the files of a content, including why the populator
  # for the content type is not being used, and the button to structure (or restructure) the files with it.
  class StructurePopulatorComponent < ApplicationComponent
    # @param [Content] content_record the mutable Content
    # @param [Contents::PopulatorSelector::Result] populator_selection
    def initialize(content_record:, populator_selection:)
      @content_record = content_record
      @populator_selection = populator_selection
      super()
    end

    def actual_populator_label
      populator_selection.actual_populator.label
    end

    def populator_for_content_type_label
      populator_selection.populator_for_content_type.label
    end

    delegate :fallback_to_default_model?, to: :populator_selection

    # @return [Array<String>] the reasons that the populator for the content type is not being used
    def reason_labels
      populator_selection.reasons.map do |reason|
        I18n.t("edit.contents.structure.populator_reasons.#{reason}")
      end
    end

    def structure_button_label
      return t('edit.contents.structure.buttons.structure') if content_record.content_file_sets.none?

      t('edit.contents.structure.buttons.restructure')
    end

    private

    attr_reader :content_record, :populator_selection
  end
end
