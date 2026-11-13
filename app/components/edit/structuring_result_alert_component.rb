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

    def call
      render SdrViewComponents::Elements::AlertComponent.new(variant:, dismissible: true) do
        safe_join([tag.p(message, class: reason_labels.any? ? 'mb-1' : 'mb-0'), reasons].compact)
      end
    end

    private

    attr_reader :structuring_result, :populator_selection

    def failed?
      structuring_result == 'structuring_failed'
    end

    def variant
      return :danger if failed?

      fallback? ? :warning : :info
    end

    def message
      return t('edit.contents.structure.results.failed') if failed?

      t('edit.contents.structure.results.structured', populator: label_for(populator_selection.actual_populator))
    end

    def fallback?
      populator_selection.actual_populator != populator_selection.populator_for_content_type
    end

    def reason_labels
      return [] if failed? || !fallback?

      populator_selection.reasons.map { |reason| t("edit.contents.structure.populator_reasons.#{reason}") }
    end

    def reasons
      return if reason_labels.empty?

      safe_join([
                  tag.p(t('edit.contents.structure.results.not_used',
                          populator: label_for(populator_selection.populator_for_content_type)), class: 'mb-1'),
                  tag.ul(safe_join(reason_labels.map { |reason_label| tag.li(reason_label) }), class: 'mb-0')
                ])
    end

    def label_for(populator)
      t("edit.contents.structure.populators.#{populator.name.demodulize.underscore}")
    end
  end
end
