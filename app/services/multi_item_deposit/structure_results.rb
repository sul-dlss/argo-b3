# frozen_string_literal: true

module MultiItemDeposit
  # The results of checking a Multi-Item Deposit's files (structuring), as shown in its summary table and report.
  class StructureResults
    # @param multi_item_deposit_action [MultiItemDepositAction]
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
    end

    # @return [Array<ItemDepositAction>] the Item Deposits with errors, then with warnings, then the rest;
    #   each in manifest order
    def item_deposit_actions
      @item_deposit_actions ||= @multi_item_deposit_action.item_deposit_actions.sort_by do |action|
        [status_rank(action), action.manifest_line_number]
      end
    end

    # @return [Integer] the number of files discovered for the Item Deposit
    def file_count(item_deposit_action)
      file_counts_by_content_id.fetch(item_deposit_action.content_id, 0)
    end

    private

    def status_rank(item_deposit_action)
      return 0 if item_deposit_action.structure_errors.any?
      return 1 if item_deposit_action.content_type_structure_warnings.any?

      2
    end

    # Counted in one query rather than one per row.
    def file_counts_by_content_id
      @file_counts_by_content_id ||= ContentFileBinary.where(content_id: item_deposit_actions.filter_map(&:content_id))
                                                      .group(:content_id).count
    end
  end
end
