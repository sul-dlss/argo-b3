# frozen_string_literal: true

module Edit
  # Component for the result of structuring the files of a content: the model (populator) that was used, why the
  # model for the content type was not used, or that structuring failed.
  class StructuringResultAlertComponent < ApplicationComponent
    # @param structuring_result [String, nil] the structuring state that has the result ('structured' or
    #   'structuring_failed'), or nil when there is no result to show
    # @param populator_selection [Contents::PopulatorSelector::Result]
    def initialize(structuring_result:, populator_selection:)
      @structuring_result = structuring_result
      @populator_selection = populator_selection
      super()
    end

    def render?
      structuring_result.present?
    end

    private

    attr_reader :structuring_result, :populator_selection

    delegate :fallback_to_default_model?, to: :populator_selection

    def failed?
      structuring_result == 'structuring_failed'
    end

    def structured_message
      t('edit.contents.structure.results.structured', populator: populator_selection.actual_populator.label)
    end
  end
end
