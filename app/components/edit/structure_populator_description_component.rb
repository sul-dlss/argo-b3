# frozen_string_literal: true

module Edit
  # Component for describing the populator that will be used to structure the files of a content,
  # including why the populator for the content type is not being used.
  class StructurePopulatorDescriptionComponent < ApplicationComponent
    # @param [Contents::PopulatorSelector::Result] populator_selection
    def initialize(populator_selection:)
      @populator_selection = populator_selection
      super()
    end

    def actual_populator_label
      label_for(populator_selection.actual_populator)
    end

    def populator_for_content_type_label
      label_for(populator_selection.populator_for_content_type)
    end

    # @return [Boolean] true when the populator for the content type cannot be used
    def fallback?
      populator_selection.actual_populator != populator_selection.populator_for_content_type
    end

    # @return [Array<String>] the reasons that the populator for the content type is not being used
    def reason_labels
      populator_selection.reasons.map do |reason|
        I18n.t("edit.contents.structure.populator_reasons.#{reason}")
      end
    end

    private

    attr_reader :populator_selection

    def label_for(populator)
      I18n.t("edit.contents.structure.populators.#{populator.name.demodulize.underscore}")
    end
  end
end
