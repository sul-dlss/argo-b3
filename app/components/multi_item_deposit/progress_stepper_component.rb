# frozen_string_literal: true

module MultiItemDeposit
  # Renders the steps of a Multi-Item Deposit (discovery, structure, and deposit) with their statuses.
  class ProgressStepperComponent < Elements::ProgressStepperComponent
    # The label and steps are translated, which can't happen until rendering, so they are provided by
    # overriding the readers rather than passed to super.
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
      super(label: nil, steps: nil, classes: 'mb-4')
    end

    def label
      t('multi_item_deposit.progress.label')
    end

    def steps
      [
        { label: t('multi_item_deposit.progress.steps.discovery'), status: discovery_status },
        { label: t('multi_item_deposit.progress.steps.structure'), status: structure_status },
        { label: t('multi_item_deposit.progress.steps.deposit'), status: deposit_status }
      ]
    end

    private

    attr_reader :multi_item_deposit_action

    # Discovery must succeed to leave the discovery step, so it is in progress until it does.
    def discovery_status
      multi_item_deposit_action.discovery_succeeded? ? :completed : :in_progress
    end

    def structure_status
      return :completed if structure_completed?
      return :in_progress if multi_item_deposit_action.structure_step?

      :pending
    end

    # Not completed after returning to the discovery step, which needs structuring again once discovery is rerun.
    def structure_completed?
      !multi_item_deposit_action.discovery_step? && multi_item_deposit_action.structuring_succeeded?
    end

    def deposit_status
      multi_item_deposit_action.deposit_step? ? :in_progress : :pending
    end
  end
end
