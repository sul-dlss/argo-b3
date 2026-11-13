# frozen_string_literal: true

module MultiItemDeposit
  # Renders the steps of a Multi-Item Deposit (discovery, structure, and deposit) with their statuses.
  class ProgressStepperComponent < ApplicationComponent
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
      super()
    end

    def call
      render Elements::ProgressStepperComponent.new(label: t('multi_item_deposit.progress.label'), steps:,
                                                    classes: 'mb-4')
    end

    private

    attr_reader :multi_item_deposit_action

    def steps
      [
        { label: t('multi_item_deposit.progress.steps.discovery'), status: discovery_status },
        { label: t('multi_item_deposit.progress.steps.structure'), status: structure_status },
        { label: t('multi_item_deposit.progress.steps.deposit'), status: deposit_status }
      ]
    end

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
