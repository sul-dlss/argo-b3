# frozen_string_literal: true

module MultiItemDeposit
  # Renders a summary of a Multi-Item Deposit's Item Deposits.
  class SummaryTableComponent < ApplicationComponent
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
      super()
    end

    # @return [Array<ItemDepositAction>] the Item Deposits in manifest order
    def item_deposit_actions
      @item_deposit_actions ||= @multi_item_deposit_action.item_deposit_actions.order(:manifest_line_number).to_a
    end

    # @return [Integer] the number of files discovered for the Item Deposit
    def file_count(item_deposit_action)
      file_counts_by_content_id.fetch(item_deposit_action.content_id, 0)
    end

    def label
      t('multi_item_deposit.summary.label')
    end

    private

    # Counted in one query rather than one per row.
    def file_counts_by_content_id
      @file_counts_by_content_id ||= ContentFileBinary.where(content_id: item_deposit_actions.filter_map(&:content_id))
                                                      .group(:content_id).count
    end
  end
end
