# frozen_string_literal: true

module MultiItemDeposit
  # Renders a summary of a Multi-Item Deposit's Item Deposits.
  class SummaryTableComponent < ApplicationComponent
    def initialize(multi_item_deposit_action:)
      @structure_results = StructureResults.new(multi_item_deposit_action:)
      super()
    end

    delegate :item_deposit_actions, :file_count, to: :@structure_results

    def label
      t('multi_item_deposit.summary.label')
    end
  end
end
